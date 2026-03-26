import http.server
import os

os.chdir(os.path.dirname(os.path.abspath(__file__)))

handler = http.server.SimpleHTTPRequestHandler
handler.extensions_map.update({'.html': 'text/html', '.js': 'application/javascript', '.css': 'text/css'})

server = http.server.HTTPServer(('localhost', 8099), handler)
print(f"Menu Reorganizer running at http://localhost:8099")
server.serve_forever()
