def load(p):
    d = open(p, 'rb').read()
    if d[:3] == b'\xef\xbb\xbf':
        return d[3:].decode('utf-8', errors='replace')
    if d[:2] == b'\xff\xfe':
        return d[2:].decode('utf-16-le', errors='replace')
    if d[:2] == b'\xfe\xff':
        return d[2:].decode('utf-16-be', errors='replace')
    if d.count(b'\x00') > len(d) // 4:
        return d.decode('utf-16-le', errors='replace')
    try:
        return d.decode('utf-8')
    except UnicodeDecodeError:
        return d.decode('latin-1')
