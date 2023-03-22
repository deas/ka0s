#!/usr/bin/env bb
(ns init_cc
  (:require
   [ka0s.config :as cfg]
   [ka0s.command :as c]
   [taoensso.timbre :as timbre]
   [clojure.tools.logging :refer [debugf]]
   [clojure.edn :as edn]
   [babashka.curl :as curl]))

(defn -main [& _args]
  (timbre/merge-config!
   {:min-level (-> cfg/common-defaults :log-level keyword)})
  (-> nil)
      println)

;; TODO: No *file* in k8s job
(when (= *file* (System/getProperty "babashka.file"))
  (-main *command-line-args*))
