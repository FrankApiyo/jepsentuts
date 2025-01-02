(ns jepsen.etcdemo
  (:require [jepsen.cli :as cli]
            [jepsen.tests :as tests]))

(defn etcd-test
  "Given an options map from the command line runner (e.g. :nodes, :ssh,
  :concurrency, ...), construct a new test map."
  [opts]
  (merge tests/noop-test
         {:pure-generators true}
         (merge opts
                {:ssh {:username "root"
                       :password "root"
                       :dummy? true
                       :strict-host-key-checking false
                       :private-key-path nil}})))

(defn -main
  "Handles command line arguments. Can either run a test, or a web server for
  browsing results."
  [& args]
  (cli/run! (merge (cli/single-test-cmd {:test-fn etcd-test}) (cli/serve-cmd))
            args))
