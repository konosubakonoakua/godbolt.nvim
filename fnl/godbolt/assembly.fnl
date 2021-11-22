;  Copyright (C) 2021 Chinmay Dalal
;
;  This file is part of godbolt.nvim.
;
;  godbolt.nvim is free software: you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation, either version 3 of the License, or
;  (at your option) any later version.
;
;  godbolt.nvim is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with godbolt.nvim.  If not, see <https://www.gnu.org/licenses/>.

(local fun vim.fn)
(local api vim.api)
(local cmd vim.cmd)
(local get-compiler (. (require :godbolt.init) :get-compiler))
(local build-cmd (. (require :godbolt.init) :build-cmd))
(var source-asm-bufs (. gb-exports :bufmap))




; Helper functions
(fn prepare-buf [text]
  "Prepare the assembly buffer: set buffer options and add text"
  (local buf (api.nvim_create_buf false true))
  (api.nvim_buf_set_option buf :filetype :asm)
  (api.nvim_buf_set_lines buf 0 0 false
    (vim.split text "\n" {:trimempty true}))
  buf)

(fn setup-aucmd [source-buf asm-buf]
  "Setup autocommands for updating highlights"
  (cmd "augroup Godbolt")
  (cmd (string.format "autocmd CursorMoved <buffer=%s> lua require('godbolt.assembly')['smolck-update'](%s, %s)" source-buf source-buf asm-buf))
  (cmd (string.format "autocmd BufLeave <buffer=%s> lua require('godbolt.assembly').clear(%s)" source-buf source-buf))
  (cmd "augroup END"))



; Highlighting
(fn clear [source-buf]
  (each [asm-buf _ (pairs (. source-asm-bufs source-buf))]
    (api.nvim_buf_clear_namespace asm-buf (. gb-exports :nsid) 0 -1)))

(fn smolck-update [source-buf asm-buf]
  (api.nvim_buf_clear_namespace asm-buf (. gb-exports :nsid) 0 -1)
  (let [entry (. source-asm-bufs source-buf asm-buf)
        offset (. entry :offset)
        asm-table (. entry :asm)
        linenum (-> (fun.getcurpos)
                    (. 2)
                    (- offset)
                    (+ 1))]
    (each [k v (pairs asm-table)]
      (if (= (type (. v :source)) :table)
        (if (= linenum (. v :source :line))
          (vim.highlight.range
           asm-buf (. gb-exports :nsid) :Visual
           [(- k 1) 0] [(- k 1) 100]
           :linewise true))))))




; Main
(fn display [response begin]
  (let [asm (accumulate [str ""
                         k v (pairs (. response :asm))]
              (.. str "\n" (. v :text)))
        source-winid (fun.win_getid)
        source-bufnr (fun.bufnr)
        asm-buf (prepare-buf asm)]
      (cmd :vsplit)
      (cmd (string.format "buffer %d" asm-buf))
      (api.nvim_win_set_option 0 :number false)
      (api.nvim_win_set_option 0 :relativenumber false)
      (api.nvim_win_set_option 0 :spell false)
      (api.nvim_win_set_option 0 :cursorline false)
      (api.nvim_set_current_win source-winid)
      (if (not (. source-asm-bufs source-bufnr))
        (tset source-asm-bufs source-bufnr {}))
      (tset source-asm-bufs source-bufnr asm-buf {:asm (. response :asm)
                                                   :offset begin})
      (setup-aucmd source-bufnr asm-buf)))

(fn get-then-display [command begin]
  "Get the response from godbolt.org as a lua table"
  (var output_arr [])
  (local _jobid (fun.jobstart command
                  {:on_stdout (fn [_ data _]
                                (vim.list_extend output_arr data))
                   :on_exit (fn [_ _ _]
                              (display (-> output_arr
                                           (fun.join)
                                           (vim.json.decode))
                                       begin))})))

(fn pre-display [begin end compiler options]
  "Prepare text for displaying and call get-then-display"
  (if vim.g.godbolt_loaded
    (let [lines (api.nvim_buf_get_lines 0 (- begin  1) end true)
          text (fun.join lines "\n")]
      (get-then-display (build-cmd compiler
                                   text
                                   options) begin))
    (api.nvim_err_writeln "setup function not called")))


{: pre-display : clear : smolck-update}