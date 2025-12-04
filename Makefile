install:
	pip install fastapi uvicorn pydantic-settings psutil
dev:
	uvicorn app.main:app --reload
uci:
	fairy-stockfish uci
show-memory:
	ps -A -o pid,rss,pcpu,command | grep python