#!/usr/bin/env python3
"""Invoice App - PythonAnywhere Deployment"""
from flask import Flask, render_template, request, jsonify
import json
import os
import uuid
from datetime import datetime

app = Flask(__name__)

# Ensure data directory exists
if not os.path.exists('data'):
    os.makedirs('data')

INVOICES_FILE = 'data/invoices.json'

def load_invoices():
    if os.path.exists(INVOICES_FILE):
        with open(INVOICES_FILE, 'r') as f:
            return json.load(f)
    return []

def save_invoices(invoices):
    with open(INVOICES_FILE, 'w') as f:
        json.dump(invoices, f, indent=2)

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/create_invoice', methods=['POST'])
def create_invoice():
    data = request.json
    
    # Generate unique invoice ID
    invoice_id = str(uuid.uuid4())[:8]
    invoice_link = f"/invoice/{invoice_id}"
    
    # Create invoice with payment method
    invoice = {
        'id': invoice_id,
        'amount': data['amount'],
        'payer': data['payer'],
        'payee': data['payee'],
        'purpose': data['purpose'],
        'date': data['date'],
        'payment_method': data.get('payment_method', 'zelle'),
        'payment_details': {
            'zelle_email': data.get('zelle_email', ''),
            'zelle_phone': data.get('zelle_phone', ''),
            'cashapp_tag': data.get('cashapp_tag', ''),
            'venmo_username': data.get('venmo_username', ''),
            'paypal_email': data.get('paypal_email', ''),
            'moncash_phone': data.get('moncash_phone', '')
        },
        'link': invoice_link,
        'created_at': datetime.now().isoformat(),
        'status': 'pending',
        'payment_date': None
    }
    
    # Save
    invoices = load_invoices()
    invoices.append(invoice)
    save_invoices(invoices)
    
    return jsonify({
        'success': True,
        'invoice_link': invoice_link,
        'invoice_id': invoice_id
    })

@app.route('/invoice/<invoice_id>')
def view_invoice(invoice_id):
    invoices = load_invoices()
    invoice = next((inv for inv in invoices if inv['id'] == invoice_id), None)
    
    if invoice:
        return render_template('invoice.html', invoice=invoice)
    return "Invoice not found", 404

@app.route('/mark_paid/<invoice_id>', methods=['POST'])
def mark_paid(invoice_id):
    data = request.json
    payment_method = data.get('payment_method', '')
    
    invoices = load_invoices()
    
    for invoice in invoices:
        if invoice['id'] == invoice_id:
            invoice['status'] = 'paid'
            invoice['payment_date'] = datetime.now().isoformat()
            invoice['actual_payment_method'] = payment_method
            save_invoices(invoices)
            return jsonify({'success': True})
    
    return jsonify({'success': False}), 404

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)


