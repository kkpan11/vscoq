(**************************************************************************)
(*                                                                        *)
(*                                 VSRocq                                  *)
(*                                                                        *)
(*                   Copyright INRIA and contributors                     *)
(*       (see version control and README file for authors & dates)        *)
(*                                                                        *)
(**************************************************************************)
(*                                                                        *)
(*   This file is distributed under the terms of the MIT License.         *)
(*   See LICENSE file.                                                    *)
(*                                                                        *)
(**************************************************************************)

(** This toplevel implements an LSP-based server language for VsCode,
    used by the VsRocq extension. *)

let log = Dm.ParTactic.TacticWorkerProcess.log 

let main_worker options ~opts:_ state =
  let initial_vernac_state = Vernacstate.freeze_full_state () in
  try Dm.ParTactic.TacticWorkerProcess.main ~st:initial_vernac_state options
  with exn ->
    let bt = Printexc.get_backtrace () in
    log (fun () -> Printexc.(to_string exn));
    log (fun () -> bt);
    flush_all ()

let vsrocqtop_specific_usage = Boot.Usage.{
  executable_name = "vsrocqtop_tactic_worker";
  extra_args = "";
  extra_options = "";
}

[%%if rocq = "8.18" || rocq = "8.19"]
let start_library top opts = Coqinit.start_library ~top opts
[%%else]
let start_library top opts =
  let intern = Vernacinterp.fs_intern in
  Coqinit.start_library ~intern ~top opts;
[%%endif]

[%%if rocq = "8.18" || rocq = "8.19" || rocq = "8.20"]
let () =
  Coqinit.init_ocaml ();
  let opts, emoptions = Coqinit.parse_arguments ~parse_extra:Dm.ParTactic.TacticWorkerProcess.parse_options ~usage:vsrocqtop_specific_usage () in
  let injections = Coqinit.init_runtime opts in
  start_library Coqargs.(dirpath_of_top opts.config.logic.toplevel_name) injections;
  log (fun () -> "started");
  Sys.(set_signal sigint Signal_ignore);
  main_worker ~opts emoptions ()
[%%else]
let () =
  Coqinit.init_ocaml ();
  let opts, emoptions = Coqinit.parse_arguments ~parse_extra:Dm.ParTactic.TacticWorkerProcess.parse_options (List.tl (Array.to_list Sys.argv)) in
  let () = Coqinit.init_runtime ~usage:vsrocqtop_specific_usage opts in
  (* not sure if init_document is useful in tactic worker *)
  let () = Coqinit.init_document opts in
  start_library (Coqinit.dirpath_of_top opts.config.logic.toplevel_name) [];
  log (fun () -> "started");
  Sys.(set_signal sigint Signal_ignore);
  main_worker ~opts emoptions ()
[%%endif]

