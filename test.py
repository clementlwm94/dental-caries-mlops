from flask import Flask, render_template, request, jsonify
import pandas as pd
from predict import predict

app = Flask(__name__)

@app.route('/', methods=['GET'])
def index():
    return render_template('index.html')

@app.route('/predict', methods=['POST'])
def predict_api():
    if request.is_json:
        data = request.get_json()
        print(data)
        # Convert to pandas DataFrame
        df = pd.DataFrame([data])
        print(df)
        
        # Make prediction
        prediction = predict(df)
        
        # Return JSON response
        return jsonify({
            'prediction': prediction,
            'status': 'success'
        })
    else:
        return jsonify({'error': 'Request must be JSON'}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9696, debug=True)