(ns ka0s.config
  (:require [clojure.string :refer [upper-case split]]
            #?(:clj [cheshire.core :as json])
            ;; [clj-yaml.core :as yaml]
            ))

(defn exit [status msg]
  (println msg)
  #?(:clj (System/exit status)
     :cljs (.exit js/process status)))

;; https://cloud.google.com/logging/docs/structured-logging : Still room to get closer to GCP
;; [yonatane.timbre-json]
(defn timbre-json-output-fn
  "timbre gcp json logging"
  [data]
  (let [{:keys [level ?err #_vargs msg_ ?ns-str ?file hostname_
                timestamp_ ?line]} data
        output-data (cond->
                     {:timestamp (force timestamp_)
                      :host (force hostname_)
                      :severity (upper-case (name level))
                      :message (force msg_)}
                      (or ?ns-str ?file) (assoc :ns (or ?ns-str ?file))
                      ?line (assoc :line ?line)
                      ?err (assoc :err "No stacktrace in bb"
                                  #_(timbre/stacktrace ?err {:stacktrace-fonts {}})))]
    #?(:clj (json/generate-string output-data)
       :cljs (.stringify js/JSON (clj->js output-data)))))

(defn deep-merge
  "Merge nested maps - quick hack"
  [a b]
  (if (map? a)
    (into a (for [[k v] b] [k (deep-merge (a k) v)]))
    b))

#?(:cljs (def node? (resolve 'js/process)))

(def default-auth (-> (or #?(:clj (System/getenv "CC_AUTH")
                             :cljs (if node?
                                     (.. js/process -env -SOLR_AUTH)
                                     (.. js/__ENV -SOLR_AUTH)))
                          "admin:admin")
                      (split #":")))

(def common-defaults {:destination nil
                      :log-level (or #?(:clj (System/getenv "LOG_LEVEL")
                                        :cljs (if node?
                                                (.. js/process -env -LOG_LEVEL)
                                                (.. js/__ENV -LOG_LEVEL)))
                                     "info")})

