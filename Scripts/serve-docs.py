#!/usr/bin/env python3
"""
Simple HTTP server for DocC static documentation.
Serves index.html for all routes (SPA-style) and static assets normally.
Usage: python3 Scripts/serve-docs.py [port]
"""
import http.server
import os
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
DOCS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs")


class DocCHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DOCS_DIR, **kwargs)

    def do_GET(self):
        # Serve static assets normally (js, css, json, images, etc.)
        path = self.translate_path(self.path)
        if os.path.isfile(path):
            return super().do_GET()

        # For documentation routes, try adding .json (DocC data files)
        json_path = path.rstrip("/") + ".json"
        if os.path.isfile(json_path):
            self.path = self.path.rstrip("/") + ".json"
            return super().do_GET()

        # For all other routes (SPA), serve index.html
        index = os.path.join(DOCS_DIR, "index.html")
        if os.path.isfile(index):
            self.path = "/index.html"
            return super().do_GET()

        return super().do_GET()


print(f"Serving DocC docs at http://localhost:{PORT}")
print(f"Open: http://localhost:{PORT}/documentation/identitykitcore")
print("Press Ctrl+C to stop.\n")

server = http.server.HTTPServer(("", PORT), DocCHandler)
try:
    server.serve_forever()
except KeyboardInterrupt:
    print("\nStopped.")
