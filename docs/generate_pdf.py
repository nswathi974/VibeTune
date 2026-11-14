import os
import re
import subprocess
import markdown

current_dir = os.path.dirname(os.path.abspath(__file__))
md_path = os.path.join(current_dir, "VIBETUNE_SRS_DOCUMENT.md")
html_path = os.path.join(current_dir, "VIBETUNE_SRS_DOCUMENT.html")
pdf_path = os.path.join(current_dir, "VIBETUNE_SRS_DOCUMENT.pdf")
edge_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

with open(md_path, 'r', encoding='utf-8') as f:
    raw_md = f.read()

# Strip initial duplicate header lines from markdown if present
clean_md = re.sub(
    r'^# Department of MCA\s*\n## Software Requirements Specification \(SRS\)\s*\n### IEEE SRS FORMAT – REFERENCE DOCUMENT\s*\n\*\*\(Applicable for Enterprise Applications[^\)]*\)\*\*\s*\n---',
    '',
    raw_md,
    flags=re.MULTILINE
).strip()

# Convert markdown to HTML with tables, code, and lists
html_body = markdown.markdown(
    clean_md,
    extensions=['tables', 'fenced_code', 'sane_lists']
)

full_html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>VibeTune - Software Requirements Specification (SRS)</title>
    <style>
        @page {{
            size: A4;
            margin: 22mm 18mm 22mm 18mm;
        }}

        * {{
            box-sizing: border-box;
        }}

        body {{
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, 'Helvetica Neue', Arial, sans-serif;
            font-size: 10.5pt;
            line-height: 1.6;
            color: #1e293b;
            background-color: #ffffff;
            margin: 0;
            padding: 0;
        }}

        /* COVER PAGE STYLING */
        .cover-page {{
            page-break-after: always;
            height: 90vh;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            text-align: center;
            padding: 40px 20px 20px 20px;
            border: 2px solid #0284c7;
            border-radius: 8px;
            background: linear-gradient(180deg, #f8fafc 0%, #ffffff 100%);
        }}

        .cover-inst {{
            font-size: 13pt;
            font-weight: 700;
            color: #475569;
            letter-spacing: 2px;
            text-transform: uppercase;
            margin-bottom: 8px;
        }}

        .cover-doc-type {{
            font-size: 21pt;
            font-weight: 800;
            color: #0369a1;
            margin: 10px 0;
            letter-spacing: 1px;
        }}

        .cover-standard {{
            display: inline-block;
            background-color: #e0f2fe;
            color: #0369a1;
            font-size: 9.5pt;
            font-weight: 700;
            padding: 5px 14px;
            border-radius: 20px;
            margin-bottom: 24px;
            letter-spacing: 0.5px;
        }}

        .cover-title-box {{
            margin: 25px 0;
            padding: 24px;
            border-top: 2px solid #0284c7;
            border-bottom: 2px solid #0284c7;
            background-color: #ffffff;
        }}

        .cover-app-title {{
            font-size: 32pt;
            font-weight: 900;
            color: #0f172a;
            margin: 0;
            letter-spacing: 3px;
        }}

        .cover-app-subtitle {{
            font-size: 12.5pt;
            font-weight: 500;
            color: #0284c7;
            margin-top: 8px;
        }}

        .cover-meta {{
            margin: 20px auto;
            width: 100%;
            max-width: 580px;
        }}

        .cover-meta table {{
            width: 100%;
            font-size: 9.5pt;
            border-collapse: collapse;
            margin: 0;
        }}

        .cover-meta th, .cover-meta td {{
            padding: 7px 10px;
            border: 1px solid #cbd5e1;
            text-align: left;
        }}

        .cover-meta th {{
            background-color: #0f172a;
            color: #ffffff;
            width: 38%;
            font-weight: 600;
        }}

        .cover-meta td {{
            background-color: #ffffff;
            color: #1e293b;
        }}

        .cover-footer {{
            font-size: 9pt;
            color: #64748b;
            margin-top: 20px;
            border-top: 1px solid #e2e8f0;
            padding-top: 10px;
        }}

        /* CONTENT STYLING */
        h1 {{
            color: #0c4a6e;
            font-size: 17pt;
            border-bottom: 2px solid #0284c7;
            padding-bottom: 5px;
            margin-top: 32px;
            margin-bottom: 14px;
            page-break-after: avoid;
        }}

        h2 {{
            color: #0369a1;
            font-size: 13.5pt;
            margin-top: 22px;
            margin-bottom: 10px;
            border-left: 4px solid #0284c7;
            padding-left: 8px;
            page-break-after: avoid;
        }}

        h3 {{
            color: #0f172a;
            font-size: 11.5pt;
            margin-top: 16px;
            margin-bottom: 8px;
            page-break-after: avoid;
        }}

        h4 {{
            color: #334155;
            font-size: 10.5pt;
            margin-top: 12px;
            margin-bottom: 6px;
            page-break-after: avoid;
        }}

        p {{
            margin-top: 0;
            margin-bottom: 10px;
            text-align: justify;
        }}

        ul, ol {{
            margin-top: 0;
            margin-bottom: 12px;
            padding-left: 24px;
        }}

        li {{
            margin-bottom: 4px;
        }}

        table {{
            width: 100%;
            border-collapse: collapse;
            margin: 14px 0 18px 0;
            font-size: 9.5pt;
            page-break-inside: avoid;
        }}

        th, td {{
            border: 1px solid #cbd5e1;
            padding: 7px 10px;
            text-align: left;
            vertical-align: top;
        }}

        th {{
            background-color: #0f172a;
            color: #ffffff;
            font-weight: 600;
        }}

        tr:nth-child(even) td {{
            background-color: #f8fafc;
        }}

        pre {{
            background-color: #f8fafc;
            border: 1px solid #e2e8f0;
            border-left: 4px solid #0284c7;
            border-radius: 4px;
            padding: 10px 12px;
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 8.5pt;
            line-height: 1.45;
            overflow-x: auto;
            white-space: pre-wrap;
            word-wrap: break-word;
            page-break-inside: avoid;
            margin: 12px 0 16px 0;
            color: #0f172a;
        }}

        code {{
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 8.5pt;
            background-color: #f1f5f9;
            padding: 2px 4px;
            border-radius: 3px;
            color: #0369a1;
        }}

        pre code {{
            background-color: transparent;
            padding: 0;
            color: inherit;
        }}

        hr {{
            border: 0;
            border-top: 1px solid #cbd5e1;
            margin: 22px 0;
        }}
    </style>
</head>
<body>

    <!-- ACADEMIC COVER PAGE -->
    <div class="cover-page">
        <div>
            <div class="cover-inst">Department of Master of Computer Applications (MCA)</div>
            <div class="cover-doc-type">Software Requirements Specification</div>
            <div class="cover-standard">IEEE SRS FORMAT – REFERENCE DOCUMENT (Annexure A)</div>
            
            <div class="cover-title-box">
                <div class="cover-app-title">VIBETUNE</div>
                <div class="cover-app-subtitle">Next-Generation Multilingual Music Streaming & Synchronized Karaoke Platform</div>
            </div>
        </div>

        <div class="cover-meta">
            <table>
                <tr><th>Project Name</th><td>VibeTune Mobile & Web Audio System</td></tr>
                <tr><th>Specification Standard</th><td>IEEE Std 830-1998 / ISO/IEC/IEEE 29148</td></tr>
                <tr><th>Academic Stream</th><td>Master of Computer Applications (MCA)</td></tr>
                <tr><th>Academic Year</th><td>2025 – 2026</td></tr>
                <tr><th>Project Author</th><td>Swathi (MCA Software Engineering Team)</td></tr>
                <tr><th>Application Type</th><td>Enterprise / Non-ML Media System (Annexure A)</td></tr>
                <tr><th>Technology Stack</th><td>Flutter (Dart 3.x), just_audio DSP, Provider</td></tr>
                <tr><th>Document Version</th><td>1.0 (Final Approved Specification)</td></tr>
            </table>
        </div>

        <div class="cover-footer">
            Confidential & Proprietary © 2025-2026 Department of MCA • IEEE Compliant SRS
        </div>
    </div>

    <!-- MAIN BODY CONTENT -->
    <div class="content-body">
        {html_body}
    </div>

</body>
</html>
"""

with open(html_path, 'w', encoding='utf-8') as f:
    f.write(full_html)

print("Generated enhanced HTML at:", html_path)

cmd = [
    edge_path,
    "--headless",
    "--disable-gpu",
    "--run-all-compositor-stages-before-draw",
    f"--print-to-pdf={pdf_path}",
    html_path
]

res = subprocess.run(cmd, capture_output=True, text=True)
if os.path.exists(pdf_path):
    print("Enhanced PDF successfully created at:", pdf_path, "Size:", os.path.getsize(pdf_path), "bytes")
else:
    print("Error creating PDF:", res.stderr)
