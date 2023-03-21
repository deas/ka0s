(ns ka0s.command
  (:require
   [ka0s.config :as cfg]
   #?(:clj [cheshire.core :as json])
   #?(:clj [org.httpkit.client :as http])
   #?(:cljs [goog.string :as gstring])
   #?(:cljs [goog.string.format])
   ;; [clojure.set :refer [difference]]
   [clojure.tools.logging :refer [debugf]]
   [clojure.string :as str :refer [join split replace-first upper-case starts-with?]]))


(defn fmt [& args]
  #?(:clj (apply clojure.core/format args)
     :cljs (str "$" (apply gstring/format args))))

(defn json->clj [s]
  #?(:clj (json/parse-string s keyword)
     :cljs (-> (.parse js/JSON s)
               (js->clj :keywordize-keys true))))

(defn clj->json [data]
  #?(:clj (json/generate-string data)
     :cljs (.stringify js/JSON (clj->js data))))


;; A bunch of http-request map templates

(defn cmd-authenticate [[username password]]
  {:url {:path   "/auth/login"}
   :method :post
   :body (clj->json {:username username :password password})})

#_(defn ba-creds [basic-auth]
    (if (string? basic-auth)
      (split #?(:clj (System/getenv basic-auth)
                :cljs (when cfg/node? (aget js/process "env" basic-auth))) #":")
      basic-auth))


(defn init-rpc
  "Extend http request template for specific destination."
  [cmd destination]
  (let [{:keys [base-url token]} destination
        path (get-in cmd [:url :path])]
    (merge cmd {:url (str base-url path)
                :headers {"Accept" "application/json"
                          "Authorization" (fmt "Bearer %s" token)
                          "Cookie" (fmt "litmus-cc-token=%s" token)}})))

(defn- ensure-ok [response]
  (let [{:keys [status headers body error]} response]
    (if-let [errmsg (cond
                      error (str error ":" body)
                      (not= 200 status) (str status ":" body)
                      :else nil)]
      (throw #?(:clj (Exception. errmsg)
                :cljs errmsg))
      response)))

(defn response-map
  "Create http response map for string body."
  [response]
  (json->clj (:body response)))

(def request #?(:clj #(let [res @(http/request %)]
                        (debugf "%s" {:request % :response res})
                        res) #_(comp deref http/request)))

(defn execute
  "Extend http request template for specific destination."
  #_([cmd]
     (execute cmd (:destination cfg/common-defaults)))
  ([cmd destination]
   (-> cmd
       (init-rpc destination)
       request
       ensure-ok)))

(defn authenticate
  ;; ([] (authenticate cfg/default-cc))
  ([username password server]
   (-> (cmd-authenticate [username password])
       (execute server)
       response-map)))

(comment
  ;; TODO: https://github.com/babashka/http-client
  ;; TODO: https://github.com/retro/graphql-builder
  (let [portal-root "http://172.18.255.200:9091"
        ;; portal-root "http://localhost:19091"
        username "admin"
        password "admin"]
    (-> (cmd-authenticate [username password])
        (execute {:base-url portal-root})
        response-map
        :access_token))
  
  ;; (-> (cmd-cluster-status) execute response-map)
  ;; Playground
  #_(let [cfg (load-env)
          output-fn (:output-fn cfg)]
      (resolve output-fn)))
