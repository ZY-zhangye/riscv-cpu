#!/usr/bin/env python3
"""
将 data.hex 转为 data.mif，适用于 Quartus altsyncram init_file。
用法：
    python tools/hex2mif.py input.hex output.mif [depth]
默认 depth = 512（2KB / 32bit words）
生成示例：
DEPTH = 512;
WIDTH = 32;
ADDRESS_RADIX = HEX;
DATA_RADIX = HEX;
CONTENT
BEGIN
  000 : 12345678;
  001 : 00000000;
  ...
END;
"""
import sys

def normalize_hex(s):
    s = s.strip()
    if not s:
        return '00000000'
    if s.startswith('0x') or s.startswith('0X'):
        s = s[2:]
    s = ''.join(s.split())
    return s.zfill(8)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: hex2mif.py input.hex output.mif [depth]')
        sys.exit(1)
    inp = sys.argv[1]
    out = sys.argv[2]
    depth = int(sys.argv[3]) if len(sys.argv) > 3 else 512

    with open(inp, 'r') as f:
        lines = [l.split('//')[0].strip() for l in f]
    vals = [normalize_hex(l) for l in lines if l.strip()]

    # pad or trim to depth
    if len(vals) < depth:
        vals += ['00000000'] * (depth - len(vals))
    else:
        vals = vals[:depth]

    with open(out, 'w') as f:
        f.write(f"DEPTH = {depth};\n")
        f.write("WIDTH = 32;\n")
        f.write("ADDRESS_RADIX = HEX;\n")
        f.write("DATA_RADIX = HEX;\n")
        f.write("CONTENT\nBEGIN\n")
        for i, v in enumerate(vals):
            addr = format(i, '03X')
            f.write(f"  {addr} : {v.upper()};\n")
        f.write("END;\n")

    print(f'Wrote {len(vals)} entries to {out}')
