#!/bin/env python
import os
import re
import sys
import binascii

def determine_format(s: str) -> str:
  parts = [part.strip() for part in s.split()]
  if looks_like_binary(parts):
    return "binary"
  if looks_like_octal(parts):
    return "octal"
  if looks_like_hex(parts):
    return "hex"
  return "text"

def looks_like_hex(parts: list[str]) -> bool:
  for part in parts:
    stripped = part.lstrip("0x")
    if not re.search("^[a-fA-F0-9]+$", stripped):
      return False
  return True

def looks_like_octal(parts: list[str]) -> bool:
  try:
    for part in parts:
      stripped = part.lstrip("0")
      i = int(stripped)
      if i > 255 or i < 1:
        return False
    return True
  except:
    return False

def looks_like_binary(parts: list[str]) -> bool:
  for part in parts:
    if not re.search("^[01]+$", part):
      return False
  return True

def text_to_bits(text, encoding='utf-8', errors='surrogatepass'):
  bits = bin(int(binascii.hexlify(text.encode(encoding, errors)), 16))[2:]
  result = bits.zfill(8 * ((len(bits) + 7) // 8))
  size, chunk_size = len(result), 8
  return " ".join([ result[i:i+chunk_size] for i in range(0, size, chunk_size) ])

def text_from_bits(bits, encoding='utf-8', errors='surrogatepass'):
  n = int(bits, 2)
  return int2bytes(n).decode(encoding, errors)

def int2bytes(i):
  hex_string = '%x' % i
  n = len(hex_string)
  return binascii.unhexlify(hex_string.zfill(n + (n & 1)))

def binary_decode(s: str) -> str:
  return text_from_bits("".join(s.split()))

def octal_decode(s: str) -> str:
  parts = s.split()
  collected = []
  for part in parts:
    collected.append(chr(int(part, 8)))
  return "".join(collected)

def text_to_hex(s: str) -> str:
  raw = s.encode("utf-8").hex()
  return " ".join([ raw[i:i+2] for i in range(0, len(raw), 2)])

def text_to_octal(s: str) -> str:
  byte_data = s.encode("utf-8")
  return " ".join(format(byte, "2o") for byte in byte_data)

def hex_decode(s: str) -> str:
  raw = "".join([ x.lstrip("0x") for x in s.split()])
  return bytes.fromhex(raw).decode("utf-8")

def main():
  raw_input = " ".join(sys.argv[1:])
  fmt = determine_format(raw_input)
  # print(f"looks like {fmt}\n")
  if fmt == "binary":
    print(binary_decode(raw_input))
  elif fmt == "octal":
    print(octal_decode(raw_input))
  elif fmt == "hex":
    print(hex_decode(raw_input))
  elif fmt == "text":
    print("binary:")
    print(text_to_bits(raw_input))
    print("octal:")
    print(text_to_octal(raw_input))
    print("hex:")
    print(text_to_hex(raw_input))


def env_flag(name: str) -> bool:
  if not name in os.environ:
    return False
  value = os.environ[name]
  return value.lower() in ["1", "y", "yes", "true"]


if __name__ == "__main__":
  main()


