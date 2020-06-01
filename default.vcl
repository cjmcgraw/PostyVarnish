vcl 4.0;
import std;
import bodyaccess;
import dynamic;

backend default {
  .host = "";
  .port = "80";
}

sub vcl_backend_response {
    set beresp.ttl = std.duration(std.getenv("VARNISH_TTL"), 10s);
}

sub vcl_init {
  new ddir = dynamic.director(
    port = std.getenv("VARNISH_BACKEND_PORT"),
    # The DNS resolution is done in the background,
    # see https://github.com/nigoroll/libvmod-dynamic/blob/master/src/vmod_dynamic.vcc#L48
    ttl = 10s,
  );
}

sub vcl_recv {
    set req.backend_hint = ddir.backend(std.getenv("VARNISH_BACKEND_HOSTNAME"));
    unset req.http.X-Body-Len;
    std.log("vcl_recv for: " + req.http.host + req.url + " method " + req.method);
    if (req.method == "POST") {
        std.log("vcl_recv change POST to GET");
        std.log("vcl_recv cache POST body");
        std.cache_req_body(500KB);
        set req.http.X-Body-Len = bodyaccess.len_req_body();
        if (req.http.X-Body-Len == "-1") {
            return(synth(400, "The request body size exceeds the limit"));
        }
        return (hash);
    }
}

sub vcl_hash {
    bodyaccess.hash_req_body();
}

sub vcl_backend_fetch {
    if (bereq.http.X-Body-Len) {
        set bereq.method = "POST";
    }
}
