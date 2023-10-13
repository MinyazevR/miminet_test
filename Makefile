init_db:
	vagrant ssh provider -c "cd /vagrant/NetFront && . venv/bin/activate && python3 app.py init"
start_flask_local:
	vagrant ssh provider -c "cd  /vagrant/NetFront && . venv/bin/activate && python3 app.py"
start_simulation:
        vagrant ssh provider -c "cd  /vagrant/NetFront && . venv/bin/activate && python3 simulation.py"
start_miminet_backend:
        vagrant ssh provider -c "cd  /vagrant/NetFront && . venv/bin/activate && python3 simulation.py"
