import time

def log_writer():
    with open("service.log", "a") as f:
        while True:
            f.write("Logger service running...\n")
            f.flush()
            time.sleep(5)

if __name__ == "__main__":
    log_writer()
