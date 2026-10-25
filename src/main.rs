use std::collections::hash_map::RandomState;
use std::collections::{HashMap, HashSet};
use std::fs::{self, File};
use std::hash::{BuildHasher, Hasher};
use std::io::{self, BufRead, BufReader, BufWriter, Read, Seek, SeekFrom, Write};
use std::net::{TcpListener, TcpStream};
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Arc, RwLock};
use std::thread;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

const MAX_CONNECTIONS: usize = 256;
const HEADER_DEADLINE: Duration = Duration::from_secs(10);
const SITE_NAME: &str = "";
const POLL: Duration = Duration::from_millis(250);

static ACTIVE: AtomicUsize = AtomicUsize::new(0);

struct Slot;
impl Drop for Slot {
    fn drop(&mut self) {
        ACTIVE.fetch_sub(1, Ordering::Relaxed);
    }
}

struct Deadline<'a> {
    stream: &'a TcpStream,
    until: Instant,
}
impl Read for Deadline<'_> {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        let left = self.until.saturating_duration_since(Instant::now());
        if left.is_zero() {
            return Err(io::ErrorKind::TimedOut.into());
        }
        self.stream.set_read_timeout(Some(left))?;
        let mut s = self.stream;
        s.read(buf)
    }
}

struct Video {
    id: String,
    name: String,
    path: PathBuf,
    size: u64,
    ext: &'static str,
    uploaded: Option<SystemTime>,
}

type Index = Arc<RwLock<Arc<Vec<Video>>>>;

struct Found {
    file_name: String,
    path: PathBuf,
    size: u64,
    modified: Option<SystemTime>,
    uploaded: Option<SystemTime>,
    ext: &'static str,
}

struct Watcher {
    dir: PathBuf,
    last: HashMap<String, (u64, Option<SystemTime>)>,
    sig: Vec<(String, u64, Option<SystemTime>, Option<SystemTime>)>,
}

impl Watcher {
    fn new(dir: PathBuf) -> Self {
        Watcher { dir, last: HashMap::new(), sig: Vec::new() }
    }

    fn poll(&mut self, trust: bool) -> Option<Vec<Video>> {
        let found = list_dir(&self.dir);
        let mut seen = HashMap::with_capacity(found.len());
        let mut ready = Vec::with_capacity(found.len());
        for f in found {
            let stamp = (f.size, f.modified);
            let stable = trust || self.last.get(&f.file_name) == Some(&stamp);
            seen.insert(f.file_name.clone(), stamp);
            if stable && f.size > 0 {
                ready.push(f);
            }
        }
        self.last = seen;
        ready.sort_by(|a, b| a.file_name.cmp(&b.file_name));
        let sig: Vec<_> = ready.iter().map(|f| (f.file_name.clone(), f.size, f.modified, f.uploaded)).collect();
        if !trust && sig == self.sig {
            return None;
        }
        self.sig = sig;
        Some(build(ready))
    }
}

fn main() {
    let mut args = std::env::args().skip(1);
    let dir = PathBuf::from(args.next().unwrap_or_else(|| "videos".into()));
    let addr = args.next().unwrap_or_else(|| "127.0.0.1:8080".into());

    let _ = fs::create_dir_all(&dir);
    let listener = TcpListener::bind(&addr).unwrap_or_else(|e| {
        eprintln!("cannot listen on {addr}: {e}");
        std::process::exit(1);
    });
    println!("xyrrhak: serving {} on http://{addr}", dir.display());

    let mut watcher = Watcher::new(dir);
    let index: Index = Arc::new(RwLock::new(Arc::new(watcher.poll(true).unwrap_or_default())));
    {
        let index = Arc::clone(&index);
        thread::spawn(move || loop {
            thread::sleep(POLL);
            if let Some(list) = watcher.poll(false) {
                *index.write().unwrap_or_else(|e| e.into_inner()) = Arc::new(list);
            }
        });
    }

    for stream in listener.incoming() {
        let Ok(stream) = stream else {
            thread::sleep(Duration::from_millis(100));
            continue;
        };
        if ACTIVE.fetch_add(1, Ordering::Relaxed) >= MAX_CONNECTIONS {
            ACTIVE.fetch_sub(1, Ordering::Relaxed);
            continue;
        }
        let slot = Slot;
        let videos = Arc::clone(&index.read().unwrap_or_else(|e| e.into_inner()));
        let _ = thread::Builder::new().spawn(move || {
            let _slot = slot;
            let _ = handle(stream, &videos);
        });
    }
}

fn hash(bytes: &[u8]) -> String {
    let h = fnv(bytes);
    format!("{:08x}", (h ^ (h >> 32)) as u32)
}

fn fnv(bytes: &[u8]) -> u64 {
    let mut h: u64 = 0xcbf29ce484222325;
    for &b in bytes {
        h ^= b as u64;
        h = h.wrapping_mul(0x100000001b3);
    }
    h
}

fn mix(mut x: u64) -> u64 {
    x = (x ^ (x >> 30)).wrapping_mul(0xbf58476d1ce4e5b9);
    x = (x ^ (x >> 27)).wrapping_mul(0x94d049bb133111eb);
    x ^ (x >> 31)
}

const ONSETS: [&str; 16] = ["kh", "vr", "sk", "th", "zh", "hr", "ks", "ss", "gh", "dr", "x", "v", "k", "z", "h", "sh"];
const NUCLEI: [&str; 8] = ["a", "aa", "ae", "i", "o", "u", "y", "e"];
const CODAS: [&str; 8] = ["", "r", "rr", "k", "sh", "th", "l", "z"];

fn xyrrhak_name(file_name: &str, salt: u64) -> (String, String) {
    let mut h = mix(fnv(file_name.as_bytes()).wrapping_add(salt.wrapping_mul(0x9e3779b97f4a7c15)));
    let mut parts = Vec::with_capacity(3);
    for _ in 0..3 {
        let s = format!("{}{}{}", ONSETS[(h & 15) as usize], NUCLEI[(h >> 4 & 7) as usize], CODAS[(h >> 7 & 7) as usize]);
        parts.push(s);
        h >>= 10;
    }
    (parts.concat(), parts.join("'"))
}

fn video_ext(path: &Path) -> Option<&'static str> {
    let ext = path.extension()?.to_str()?;
    ["webm", "mp4"].into_iter().find(|e| ext.eq_ignore_ascii_case(e))
}

fn mime(ext: &str) -> &'static str {
    match ext {
        "mp4" => "video/mp4",
        _ => "video/webm",
    }
}

fn list_dir(dir: &Path) -> Vec<Found> {
    let mut list = Vec::new();
    let Ok(entries) = fs::read_dir(dir) else { return list };
    for entry in entries.flatten() {
        let path = entry.path();
        let Some(ext) = video_ext(&path) else { continue };
        let Ok(real) = fs::canonicalize(&path) else { continue };
        if video_ext(&real) != Some(ext) {
            continue;
        }
        let Ok(meta) = fs::metadata(&real) else { continue };
        if !meta.is_file() {
            continue;
        }
        let file_name = entry.file_name().to_string_lossy().into_owned();
        let modified = meta.modified().ok();
        let uploaded = meta.created().ok().or(modified);
        list.push(Found { file_name, path: real, size: meta.len(), modified, uploaded, ext });
    }
    list
}

fn build(found: Vec<Found>) -> Vec<Video> {
    let mut taken = HashSet::with_capacity(found.len());
    let mut list = Vec::with_capacity(found.len());
    for f in found {
        let mut salt = 0;
        let (id, name) = loop {
            let (id, name) = xyrrhak_name(&f.file_name, salt);
            if taken.insert(id.clone()) {
                break (id, name);
            }
            salt += 1;
        };
        list.push(Video { id, name, path: f.path, size: f.size, ext: f.ext, uploaded: f.uploaded });
    }
    list.sort_by(|a, b| a.uploaded.cmp(&b.uploaded).then_with(|| a.id.cmp(&b.id)));
    list
}

fn random(n: usize) -> usize {
    let mut h = RandomState::new().build_hasher();
    let nanos = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_nanos()).unwrap_or(0);
    h.write_u128(nanos);
    (h.finish() % n as u64) as usize
}

fn handle(stream: TcpStream, videos: &[Video]) -> io::Result<()> {
    stream.set_write_timeout(Some(Duration::from_secs(60)))?;

    let deadline = Deadline { stream: &stream, until: Instant::now() + HEADER_DEADLINE };
    let mut reader = BufReader::new(deadline.take(16 * 1024));
    let mut request_line = String::new();
    reader.read_line(&mut request_line)?;
    let mut parts = request_line.split_whitespace();
    let method = parts.next().unwrap_or("").to_string();
    let target = parts.next().unwrap_or("/").to_string();

    let mut range = None;
    loop {
        let mut line = String::new();
        if reader.read_line(&mut line)? == 0 {
            break;
        }
        let line = line.trim_end();
        if line.is_empty() {
            break;
        }
        if let Some((k, v)) = line.split_once(':') {
            if k.trim().eq_ignore_ascii_case("range") {
                range = Some(v.trim().to_string());
            }
        }
    }
    drop(reader);

    let mut out = BufWriter::with_capacity(64 * 1024, &stream);
    let head = method == "HEAD";
    if method != "GET" && !head {
        send(&mut out, "405 Method Not Allowed", "text/plain", b"405", head, "Allow: GET, HEAD\r\n")?;
        return out.flush();
    }

    let (path, query) = target.split_once('?').unwrap_or((&target, ""));

    match path {
        "/khesh.css" => send(&mut out, "200 OK", "text/css; charset=utf-8", style_css().as_bytes(), head, CACHE_FOREVER)?,
        "/xyrrhak.woff" => send(&mut out, "200 OK", "font/woff", XYRRHAK_FONT, head, CACHE_FOREVER)?,
        "/vyrr.js" => send(&mut out, "200 OK", "text/javascript; charset=utf-8", SCRIPT.as_bytes(), head, CACHE_FOREVER)?,
        "/vhess" => send_html(&mut out, "200 OK", &page("vhess", ABOUT), head)?,

        "/" | "/kshvaar" => {
            let not = query.split('&').find_map(|kv| kv.strip_prefix("not="));
            let mut pool: Vec<&Video> = videos.iter().filter(|v| Some(v.id.as_str()) != not).collect();
            if pool.is_empty() {
                pool = videos.iter().collect();
            }
            if pool.is_empty() {
                send_html(&mut out, "200 OK", &page("skra'th", EMPTY), head)?;
            } else {
                let loc = format!("/v/{}", pool[random(pool.len())].id);
                let extra = format!("Location: {loc}\r\nCache-Control: no-store\r\n");
                send(&mut out, "302 Found", "text/plain", b"", head, &extra)?;
            }
        }

        p if p.starts_with("/v/") => match videos.iter().position(|v| v.id == p[3..]) {
            Some(i) => send_html(&mut out, "200 OK", &video_page(&videos, i), head)?,
            None => send_html(&mut out, "404 Not Found", &not_found_page(), head)?,
        },

        p if p.starts_with("/f/") => {
            let id = p[3..].split('.').next().unwrap_or("");
            match videos.iter().find(|v| v.id == id) {
                Some(v) => serve_file(&mut out, v, range.as_deref(), head)?,
                None => send(&mut out, "404 Not Found", "text/plain", b"404", head, "")?,
            }
        }

        _ => send_html(&mut out, "404 Not Found", &not_found_page(), head)?,
    }
    out.flush()
}

fn send(out: &mut impl Write, status: &str, ctype: &str, body: &[u8], head: bool, extra: &str) -> io::Result<()> {
    write!(
        out,
        "HTTP/1.1 {status}\r\nContent-Type: {ctype}\r\nContent-Length: {}\r\nConnection: close\r\n{extra}\r\n",
        body.len()
    )?;
    if !head {
        out.write_all(body)?;
    }
    Ok(())
}

fn send_html(out: &mut impl Write, status: &str, html: &str, head: bool) -> io::Result<()> {
    send(out, status, "text/html; charset=utf-8", html.as_bytes(), head, "")
}

enum Range {
    Full,
    Part(u64, u64),
    Bad,
}

fn parse_range(header: Option<&str>, size: u64) -> Range {
    let Some(spec) = header.and_then(|h| h.strip_prefix("bytes=")) else { return Range::Full };
    let spec = spec.split(',').next().unwrap_or("").trim();
    let Some((a, b)) = spec.split_once('-') else { return Range::Full };
    if size == 0 {
        return Range::Bad;
    }
    let (start, end) = if a.is_empty() {
        match b.parse::<u64>() {
            Ok(0) => return Range::Bad,
            Ok(n) => (size.saturating_sub(n), size - 1),
            Err(_) => return Range::Full,
        }
    } else {
        let Ok(start) = a.parse::<u64>() else { return Range::Full };
        let end = if b.is_empty() {
            size - 1
        } else {
            match b.parse::<u64>() {
                Ok(e) => e.min(size - 1),
                Err(_) => return Range::Full,
            }
        };
        (start, end)
    };
    if start > end || start >= size {
        return Range::Bad;
    }
    Range::Part(start, end)
}

fn serve_file(out: &mut impl Write, v: &Video, range: Option<&str>, head: bool) -> io::Result<()> {
    let mut f = File::open(&v.path)?;
    let size = f.metadata()?.len();
    let (status, start, len, extra) = match parse_range(range, size) {
        Range::Full => ("200 OK", 0, size, String::new()),
        Range::Part(a, b) => ("206 Partial Content", a, b - a + 1, format!("Content-Range: bytes {a}-{b}/{size}\r\n")),
        Range::Bad => {
            let extra = format!("Content-Range: bytes */{size}\r\n");
            return send(out, "416 Range Not Satisfiable", "text/plain", b"", head, &extra);
        }
    };
    write!(
        out,
        "HTTP/1.1 {status}\r\nContent-Type: {}\r\nContent-Length: {len}\r\nAccept-Ranges: bytes\r\nConnection: close\r\n{extra}\r\n",
        mime(v.ext)
    )?;
    if !head {
        f.seek(SeekFrom::Start(start))?;
        io::copy(&mut f.take(len), out)?;
    }
    Ok(())
}

const STYLE_CSS: &str = include_str!("../web/khesh.css");
const XYRRHAK_FONT: &[u8] = include_bytes!("../web/xyrrhak.woff");
const SCRIPT: &str = include_str!("../web/vyrr.js");
const LAYOUT: &str = include_str!("../web/khaarn.html");
const VIDEO: &str = include_str!("../web/hrrghaz.html");
const EMPTY: &str = include_str!("../web/skrath.html");
const ABOUT: &str = include_str!("../web/vhess.html");
const NOT_FOUND: &str = include_str!("../web/vrrshkal.html");

fn render(tpl: &str, vars: &[(&str, &str)]) -> String {
    let mut out = String::with_capacity(tpl.len() * 2);
    let mut rest = tpl;
    while let Some(start) = rest.find("{{") {
        out.push_str(&rest[..start]);
        let after = &rest[start + 2..];
        let Some(end) = after.find("}}") else {
            rest = &rest[start..];
            break;
        };
        let key = after[..end].trim();
        match vars.iter().find(|(k, _)| *k == key) {
            Some((_, v)) => out.push_str(v),
            None => out.push_str(&rest[start..start + 2 + end + 2]),
        }
        rest = &after[end + 2..];
    }
    out.push_str(rest);
    out
}

const CACHE_FOREVER: &str = "Cache-Control: public, max-age=31536000, immutable\r\n";

fn style_css() -> String {
    render(STYLE_CSS, &[("kaidrun", &hash(XYRRHAK_FONT))])
}

fn page(title: &str, content: &str) -> String {
    let site_name = esc(SITE_NAME);
    let title = match SITE_NAME {
        "" => esc(title),
        _ => format!("{} :: {site_name}", esc(title)),
    };
    let css_v = hash(style_css().as_bytes());
    let font_v = hash(XYRRHAK_FONT);
    let js_v = hash(SCRIPT.as_bytes());
    render(
        LAYOUT,
        &[
            ("khor", &title),
            ("ssukh", &site_name),
            ("dhrum", content),
            ("kheshdrun", &css_v),
            ("kaidrun", &font_v),
            ("vyrrdrun", &js_v),
        ],
    )
}

fn video_page(videos: &[Video], i: usize) -> String {
    let v = &videos[i];
    let n = videos.len();
    let content = render(
        VIDEO,
        &[
            ("ssa", &v.id),
            ("ssahak", &v.name),
            ("ssyr", v.ext),
            ("thruk", &videos[(i + n - 1) % n].id),
            ("zhaal", &videos[(i + 1) % n].id),
            ("vraakith", &fmt_size(v.size)),
            ("ssen", &(i + 1).to_string()),
            ("thal", &n.to_string()),
        ],
    );
    page(&v.name, &content)
}

fn not_found_page() -> String {
    page("vrrsh'kal", NOT_FOUND)
}

fn esc(s: &str) -> String {
    let mut o = String::with_capacity(s.len());
    for c in s.chars() {
        match c {
            '&' => o.push_str("&amp;"),
            '<' => o.push_str("&lt;"),
            '>' => o.push_str("&gt;"),
            '"' => o.push_str("&quot;"),
            '\'' => o.push_str("&#39;"),
            _ => o.push(c),
        }
    }
    o
}

fn fmt_size(bytes: u64) -> String {
    let mb = bytes as f64 / (1024.0 * 1024.0);
    if mb >= 1024.0 {
        format!("{:.2} ghss", mb / 1024.0)
    } else if mb < 1.0 {
        format!("{} kss", bytes.div_ceil(1024))
    } else {
        format!("{mb:.1} mhss")
    }
}
