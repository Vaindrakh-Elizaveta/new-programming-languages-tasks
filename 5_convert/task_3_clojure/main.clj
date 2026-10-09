(require '[clojure.string :as string])

(defn parse-json [text]
  (let [position (atom 0)
        length (count text)]
    (letfn [(current-character []
              (when (< @position length)
                (.charAt text @position)))
            (take-character []
              (let [character (current-character)]
                (when character
                  (swap! position inc))
                character))
            (skip-whitespace []
              (while (and (< @position length)
                          (Character/isWhitespace (.charAt text @position)))
                (swap! position inc)))
            (expect-character [expected]
              (let [actual (take-character)]
                (when (not= actual expected)
                  (throw (ex-info (str "Expected '" expected "'") {:position @position})))))
            (parse-string []
              (expect-character \" )
              (loop [builder (StringBuilder.)]
                (let [character (take-character)]
                  (cond
                    (nil? character)
                    (throw (ex-info "Unclosed JSON string" {:position @position}))

                    (= character \" )
                    (.toString builder)

                    (= character \\)
                    (let [escaped (take-character)]
                      (case escaped
                        \" (.append builder \" )
                        \\ (.append builder \\)
                        \/ (.append builder \/)
                        \b (.append builder (char 8))
                        \f (.append builder (char 12))
                        \n (.append builder \newline)
                        \r (.append builder \return)
                        \t (.append builder \tab)
                        \u (let [start @position
                                 end (+ start 4)]
                             (when (> end length)
                               (throw (ex-info "Invalid Unicode escape" {:position start})))
                             (let [digits (subs text start end)]
                               (try
                                 (.append builder (char (Integer/parseInt digits 16)))
                                 (catch NumberFormatException _
                                   (throw (ex-info "Invalid Unicode escape" {:position start})))))
                             (reset! position end))
                        (throw (ex-info "Invalid escape sequence" {:position @position})))
                      (recur builder))

                    (< (int character) 32)
                    (throw (ex-info "Control character in JSON string" {:position @position}))

                    :else
                    (do
                      (.append builder character)
                      (recur builder))))))
            (parse-number []
              (let [start @position]
                (while (and (< @position length)
                            (re-matches #"[0-9eE+\-.]" (str (.charAt text @position))))
                  (swap! position inc))
                (let [token (subs text start @position)]
                  (when-not (re-matches #"-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?" token)
                    (throw (ex-info "Invalid JSON number" {:position start})))
                  (bigdec token))))
            (parse-literal [literal value]
              (let [end (+ @position (count literal))]
                (when (or (> end length) (not= literal (subs text @position end)))
                  (throw (ex-info (str "Expected " literal) {:position @position})))
                (reset! position end)
                value))
            (parse-array []
              (expect-character \[)
              (skip-whitespace)
              (if (= (current-character) \])
                (do (take-character) [])
                (loop [values []]
                  (let [value (parse-value)]
                    (skip-whitespace)
                    (case (take-character)
                      \, (do (skip-whitespace) (recur (conj values value)))
                      \] (conj values value)
                      (throw (ex-info "Expected ',' or ']'" {:position @position})))))))
            (parse-object []
              (expect-character \{)
              (skip-whitespace)
              (let [result (java.util.LinkedHashMap.)]
                (if (= (current-character) \})
                  (do (take-character) result)
                  (loop []
                    (when (not= (current-character) \" )
                      (throw (ex-info "Expected a string key" {:position @position})))
                    (let [key (parse-string)]
                      (skip-whitespace)
                      (expect-character \:)
                      (skip-whitespace)
                      (.put result key (parse-value))
                      (skip-whitespace)
                      (case (take-character)
                        \, (do (skip-whitespace) (recur))
                        \} result
                        (throw (ex-info "Expected ',' or '}'" {:position @position}))))))))
            (parse-value []
              (skip-whitespace)
              (case (current-character)
                \" (parse-string)
                \{ (parse-object)
                \[ (parse-array)
                \t (parse-literal "true" true)
                \f (parse-literal "false" false)
                \n (parse-literal "null" nil)
                (if (and (current-character)
                         (or (= (current-character) \-)
                             (Character/isDigit (current-character))))
                  (parse-number)
                  (throw (ex-info "Unexpected JSON value" {:position @position})))))]
      (let [value (parse-value)]
        (skip-whitespace)
        (when (< @position length)
          (throw (ex-info "Unexpected data after JSON value" {:position @position})))
        value))))

(defn simple-value [value]
  (cond
    (nil? value) ""
    (string? value) value
    (number? value) (str value)
    (true? value) "true"
    (false? value) "false"
    :else (throw (ex-info "Nested arrays and objects are not supported" {:value value}))))

(defn escape-csv [value]
  (let [text (simple-value value)]
    (if (or (string/includes? text ",")
            (string/includes? text "\"")
            (string/includes? text "\n")
            (string/includes? text "\r"))
      (str "\"" (string/replace text "\"" "\"\"") "\"")
      text)))

(defn json-to-csv [input-path output-path]
  (let [data (parse-json (slurp input-path :encoding "UTF-8"))]
    (when-not (vector? data)
      (throw (ex-info "The top-level JSON value must be an array" {})))
    (when-not (every? #(instance? java.util.Map %) data)
      (throw (ex-info "Every array element must be an object" {})))

    (if (empty? data)
      (spit output-path "" :encoding "UTF-8")
      (let [headers (vec (.keySet ^java.util.Map (first data)))
            expected-keys (set headers)]
        (doseq [[index item] (map-indexed vector data)]
          (when (or (not= expected-keys (set (.keySet ^java.util.Map item)))
                    (not= (count headers) (.size ^java.util.Map item)))
            (throw (ex-info (str "Object " (inc index) " has a different set of fields") {}))))

        (let [lines (cons
                      (string/join "," (map escape-csv headers))
                      (map (fn [item]
                             (string/join "," (map #(escape-csv (.get ^java.util.Map item %)) headers)))
                           data))]
          (spit output-path (str (string/join "\r\n" lines) "\r\n") :encoding "UTF-8"))))
    (println (str "Converted " (count data) " records to " output-path))))

(let [[input-path output-path] *command-line-args*
      input-path (or input-path "input.json")
      output-path (or output-path "output.csv")]
  (try
    (json-to-csv input-path output-path)
    (catch Exception error
      (binding [*out* *err*]
        (println (str "Error: " (.getMessage error))))
      (System/exit 1))))
