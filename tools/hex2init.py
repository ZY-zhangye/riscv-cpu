#!/usr/bin/env python3
"""
简单脚本：将 data.hex 转为 data_init.vh
每行 data.hex 预期为 32-bit hex（可带或不带 0x 前缀）。
输出文件为 data_init.vh，内容示例：
    ram[0] = 32'h00000000;
    ram[1] = 32'h12345678;

用法：
    python tools/hex2init.py data.hex rtl/data_init.vh
"""
import sys

def normalize_hex(s):
    s = s.strip()
    if s.startswith('0x') or s.startswith('0X'):
        s = s[2:]
    return s.zfill(8)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: hex2init.py input.hex output.vh')
        sys.exit(1)
    inp = sys.argv[1]
    out = sys.argv[2]
    with open(inp, 'r') as f:
        lines = [l.split('//')[0].strip() for l in f]
    vals = [l for l in lines if l]
    with open(out, 'w') as f:
        for i, v in enumerate(vals):
            hv = normalize_hex(v)
            f.write(f"ram[{i}] = 32'h{hv};\n")
    print(f'Wrote {len(vals)} entries to {out}')
