# locust --host http://172.18.255.202 -f ./locustfile.py --headless
# locust --host http://front-end.sock-shop.svc.cluster.local -f /config/locustfile.py --clients 5 --hatch-rate 5 --num-request 100 --no-web

import base64

from locust import HttpUser, TaskSet, task, constant
from random import randint, choice


class WebTasks(TaskSet):

    @task
    def load(self):
        base64string = base64.b64encode(bytes('user:password', 'utf-8')).decode("ascii")
        catalogue = self.client.get("/catalogue").json()
        category_item = choice(catalogue)
        item_id = category_item["id"]

        self.client.get("/")
        self.client.get("/login", headers={"Authorization":"Basic %s" % base64string})
        self.client.get("/category.html")
        self.client.get("/detail.html?id={}".format(item_id))
        self.client.delete("/cart")
        self.client.post("/cart", json={"id": item_id, "quantity": 1})
        self.client.get("/basket.html")
        # self.client.post("/orders") # TODO: Roughly 10% errors?


class Web(HttpUser):
    tasks = {WebTasks:2}
    # wait_time = constant(5)    
    # task_set = WebTasks
    min_wait = 0
    max_wait = 0
    #@task
    #def my_task(self):
    #    pass