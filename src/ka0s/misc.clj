(ns ka0s.misc
  ;; (:require [clojure.java.io :as io])
  (:import [java.util Base64]
           [java.net URLEncoder URLDecoder]))

;; Borrowed from httpkit bc not in version shipping with bb atm
(defn url-encode [s]
  (URLEncoder/encode (str s) "utf8"))

(defn url-decode [s]
  (URLDecoder/decode s "utf8"))

(defn encode-base64 [b]
  (.encodeToString (Base64/getEncoder) b))