netsh interface ipv6 set prefixpolicy ::ffff:0:0/96 50 0
netsh interface ipv6 set prefixpolicy ::1/128 40 1
netsh interface ipv6 set prefixpolicy ::/0 30 2
netsh interface ipv6 set prefixpolicy 2002::/16 20 3
netsh interface ipv6 set prefixpolicy 2001::/32 5 5
netsh interface ipv6 set prefixpolicy fc00::/7 3 13
netsh interface ipv6 set prefixpolicy fec0::/10 1 11
netsh interface ipv6 set prefixpolicy 3ffe::/16 1 12
netsh interface ipv6 set prefixpolicy ::/96 1 4
