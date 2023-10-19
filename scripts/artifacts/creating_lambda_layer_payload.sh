mkdir mylambda-layer-with-requests290
cd mylambda-layer-with-requests290
python3 -m venv test_venv
source test_venv/bin/activate
python --version
mkdir python
pip install requests==2.29.0 -t python
zip -r requests.zip python
