(ns jepsen.etcdemo
  (:require [clojure.tools.logging :refer [info warn]]
            [clojure.string :as str]
            [jepsen.control :as c :refer [|]]
            [jepsen [cli :as cli] [control :as c] [db :as jepsen-db]
             [tests :as tests]]
            [jepsen.control.util :as cu]
            [jepsen.os.debian :as debian]))

(defn db
  "Etcd DB for a particular version"
  [version]
  (reify
   jepsen-db/DB
     (setup! [_ test node] (info node "Installing etcd" version))
     (teardown! [_ test node] (info node "tearing down etcd"))))

(defn read-file-strings
  [file-path]
  (let [file-content (slurp file-path)] (str/split-lines file-content)))

(defn get-lxc-hosts [] (read-file-strings "lxc-hosts.txt"))

(defn etcd-test
  "Given an options map from the command line runner (e.g. :nodes, :ssh,
  :concurrency, ...), construct a new test map."
  [opts]
  (merge tests/noop-test
         (merge opts
                {:nodes (get-lxc-hosts)
                 :ssh {:username "root"
                       :password "root"
                       ;; :dummy? true
                       :strict-host-key-checking false
                       :private-key-path nil}})
         {:name "etcd"
          :os debian/os
          :db (db "v3.1.5")
          :pure-generators true}))

(defn -main
  "Handles command line arguments. Can either run a test, or a web server for
  browsing results."
  [& args]
  (cli/run! (merge (cli/single-test-cmd {:test-fn etcd-test}) (cli/serve-cmd))
            args))
