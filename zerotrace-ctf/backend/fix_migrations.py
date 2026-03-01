import glob

files = glob.glob('migrations/versions/*.py')
for f in files:
    content = open(f).read()
    new_content = content.replace("sa.text('now()')", "sa.text('CURRENT_TIMESTAMP')")
    open(f, 'w').write(new_content)
    if content != new_content:
        print(f"Fixed: {f}")
    else:
        print(f"No change: {f}")
