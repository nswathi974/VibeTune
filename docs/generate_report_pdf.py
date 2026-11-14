import os
import re
import subprocess
import markdown

current_dir = os.path.dirname(os.path.abspath(__file__))
md_path = os.path.join(current_dir, "VIBETUNE_MCA_PROJECT_REPORT_AND_VIVA_GUIDE.md")
html_path = os.path.join(current_dir, "VIBETUNE_MCA_PROJECT_REPORT_AND_VIVA_GUIDE.html")
pdf_path = os.path.join(current_dir, "VIBETUNE_MCA_PROJECT_REPORT_AND_VIVA_GUIDE.pdf")
edge_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

with open(md_path, 'r', encoding='utf-8') as f:
    raw_md = f.read()

# Convert markdown to HTML with tables, code, and lists
html_body = markdown.markdown(
    raw_md,
    extensions=['tables', 'fenced_code', 'sane_lists']
)

full_html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>VibeTune - MCA Final Year Project Report & Viva Voce Guide</title>
    <style>
        @page {{
            size: A4;
            margin: 20mm 18mm 20mm 18mm;
        }}

        * {{
            box-sizing: border-box;
        }}

        body {{
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, 'Helvetica Neue', Arial, sans-serif;
            font-size: 10pt;
            line-height: 1.55;
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
            padding: 35px 20px 20px 20px;
            border: 2px solid #7c3aed;
            border-radius: 8px;
            background: linear-gradient(180deg, #faf5ff 0%, #ffffff 100%);
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
            color: #6d28d9;
            margin: 10px 0;
            letter-spacing: 1px;
        }}

        .cover-standard {{
            display: inline-block;
            background-color: #ede9fe;
            color: #6d28d9;
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
            border-top: 2px solid #7c3aed;
            border-bottom: 2px solid #7c3aed;
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
            color: #7c3aed;
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
            background-color: #1e1b4b;
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
            color: #4c1d95;
            font-size: 16pt;
            border-bottom: 2px solid #7c3aed;
            padding-bottom: 4px;
            margin-top: 28px;
            margin-bottom: 12px;
            page-break-after: avoid;
        }}

        h2 {{
            color: #6d28d9;
            font-size: 13pt;
            margin-top: 20px;
            margin-bottom: 8px;
            border-left: 4px solid #7c3aed;
            padding-left: 8px;
            page-break-after: avoid;
        }}

        h3 {{
            color: #1e293b;
            font-size: 11pt;
            margin-top: 14px;
            margin-bottom: 6px;
            page-break-after: avoid;
        }}

        p {{
            margin: 6px 0;
            text-align: justify;
        }}

        ul, ol {{
            margin: 6px 0 10px 0;
            padding-left: 20px;
        }}

        li {{
            margin-bottom: 3px;
        }}

        table {{
            width: 100%;
            border-collapse: collapse;
            margin: 12px 0 16px 0;
            font-size: 9pt;
            page-break-inside: avoid;
        }}

        th, td {{
            border: 1px solid #cbd5e1;
            padding: 6px 8px;
            text-align: left;
            vertical-align: top;
        }}

        th {{
            background-color: #f1f5f9;
            color: #0f172a;
            font-weight: 600;
        }}

        tr:nth-child(even) td {{
            background-color: #f8fafc;
        }}

        code {{
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 8.5pt;
            background-color: #f1f5f9;
            padding: 2px 4px;
            border-radius: 4px;
            color: #0f172a;
        }}

        pre {{
            background-color: #0f172a;
            color: #f8fafc;
            padding: 10px 12px;
            border-radius: 6px;
            font-size: 8.5pt;
            overflow-x: auto;
            margin: 10px 0;
            page-break-inside: avoid;
        }}

        pre code {{
            background-color: transparent;
            color: #f8fafc;
            padding: 0;
        }}

        hr {{
            border: none;
            border-top: 1px solid #e2e8f0;
            margin: 18px 0;
        }}
    </style>
</head>
<body>

    <!-- COVER PAGE -->
    <div class="cover-page">
        <div>
            <div class="cover-inst">Department of Master of Computer Applications</div>
            <div class="cover-doc-type">MCA FINAL YEAR PROJECT REPORT</div>
            <div class="cover-standard">& COMPREHENSIVE VIVA VOCE DEMONSTRATION GUIDE</div>
        </div>

        <div class="cover-title-box">
            <div class="cover-app-title">VIBETUNE</div>
            <div class="cover-app-subtitle">A Cross-Platform Synchronized Lyrics, Multilingual Translation & Karaoke Music Application</div>
        </div>

        <div class="cover-meta">
            <table>
                <tr><th>Project Name</th><td>VibeTune Music & Karaoke Application</td></tr>
                <tr><th>Degree / Course</th><td>Master of Computer Applications (MCA)</td></tr>
                <tr><th>Frontend Stack</th><td>Flutter 3.x, Dart, Material 3, Audioplayers</td></tr>
                <tr><th>Backend Stack</th><td>Node.js, Express.js, Mongoose ODM</td></tr>
                <tr><th>Database</th><td>MongoDB Atlas (Cloud Cluster: <code>vibetune_db</code>)</td></tr>
                <tr><th>External APIs</th><td>LRCLIB API (Lyrics), MyMemory API (Translation)</td></tr>
                <tr><th>Target Platforms</th><td>Android (APK & Emulators), Cross-Platform</td></tr>
                <tr><th>Academic Year</th><td>2025 – 2026</td></tr>
            </table>
        </div>

        <div class="cover-footer">
            Confidential &amp; Proprietary &bull; Master of Computer Applications Final Year Submission
        </div>
    </div>

    <!-- MAIN BODY -->
    <div class="content-container">
        {html_body}
    </div>

</body>
</html>
"""

with open(html_path, 'w', encoding='utf-8') as f:
    f.write(full_html)

print(f"Generated enhanced HTML at: {html_path}")

cmd = [
    edge_path,
    "--headless",
    "--disable-gpu",
    "--no-pdf-header-footer",
    f"--print-to-pdf={pdf_path}",
    html_path
]

res = subprocess.run(cmd, capture_output=True, text=True)
if res.returncode == 0 and os.path.exists(pdf_path):
    print(f"Enhanced PDF successfully created at: {pdf_path} Size: {os.path.getsize(pdf_path)} bytes")
else:
    print(f"PDF creation completed with returncode: {res.returncode}")
