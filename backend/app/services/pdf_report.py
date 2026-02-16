from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from datetime import datetime

def create_report(result, memory_score, transcript, speech_features, explanation):
    filename = f"report_{datetime.now().timestamp()}.pdf"
    c = canvas.Canvas(filename, pagesize=A4)

    y = 800

    c.setFont("Helvetica-Bold", 16)
    c.drawString(180, y, "Cognitive Screening Report")
    y -= 40

    c.setFont("Helvetica", 12)
    c.drawString(50, y, f"Date: {datetime.now().strftime('%d-%m-%Y %H:%M')}")
    y -= 30

    c.drawString(50, y, f"Memory Score: {memory_score}/100")
    y -= 25

    c.drawString(50, y, f"Risk Score: {result['risk_score']}")
    y -= 25

    c.drawString(50, y, f"Risk Level: {result['risk_level']}")
    y -= 40

    c.drawString(50, y, "Speech Transcript:")
    y -= 20

    for line in transcript.split("."):
        c.drawString(60, y, line.strip())
        y -= 18

    y -= 20
    c.drawString(50, y, "Speech Metrics:")
    y -= 20

    for key, value in speech_features.items():
        c.drawString(60, y, f"{key}: {round(value,2)}")
        y -= 18
    
    y -= 20
    c.drawString(50, y, "AI Explanation:")
    y -= 20

    for reason in explanation:
        c.drawString(60, y, f"- {reason}")
        y -= 18
        
    c.save()
    return filename
