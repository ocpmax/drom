(**************************************************************************)
(*                                                                        *)
(*    Copyright 2020 OCamlPro & Origin Labs                               *)
(*                                                                        *)
(*  All rights reserved. This file is distributed under the terms of the  *)
(*  GNU Lesser General Public License version 2.1, with the special       *)
(*  exception on linking described in the file LICENSE.                   *)
(*                                                                        *)
(**************************************************************************)

open Types

let template_src_dune package =
  let b = Buffer.create 1000 in
  let dependencies = List.map (fun (name, d) ->
      match d.depname with
      | None -> name
      | Some name -> name)  (Misc.p_dependencies package) in
  let p_mode = Misc.p_mode package in
  let dependencies =
    match p_mode with
    | Binary -> dependencies
    | Javascript ->
      if List.mem "js_of_ocaml" dependencies then
        dependencies
      else
        "js_of_ocaml" :: dependencies
  in
  let libraries = String.concat " " dependencies in

  begin
    match Misc.p_kind package with
    | Program ->
      Printf.bprintf b {|
(executable
 (name main)
 (public_name %s)
 (libraries %s)%s
)
|}
        package.name
        libraries
        (match p_mode with
         | Binary -> ""
         | Javascript ->
           {|
 (mode js)
 (preprocess (pps js_of_ocaml-ppx))|}
        )

    | Library ->
      Printf.bprintf b {|
(library
 (name %s)
 (public_name %s)%s
 (libraries %s)%s
)
|}
        ( Misc.library_name package)
        package.name
        (if not ( Misc.p_pack_modules package ) then {|
 (wrapped false)|}
         else "")
        libraries
        (match p_mode with
         | Binary -> ""
         | Javascript ->
           {|
 (preprocess (pps js_of_ocaml-ppx))|}
        )

    | Both ->
      Printf.bprintf b {|
(library
 (name %s)
 (public_name %s_lib)
 (libraries %s)%s
)
|}
        ( Misc.library_name package )
        package.name libraries
        (match p_mode with
         | Binary -> ""
         | Javascript ->
           {|
 (preprocess (pps js_of_ocaml-ppx))|}
        )
  end;

  begin
    match Sys.readdir package.dir with
    | exception _ -> ()
    | files -> Array.iter (fun file ->
        if Filename.check_suffix file ".mll" then
          Printf.bprintf b "(ocamllex %s)\n"
            ( Filename.chop_suffix file ".mll")
        else
        if Filename.check_suffix file ".mly" then
          Printf.bprintf b "(ocamlyacc %s)\n"
            ( Filename.chop_suffix file ".mly")
      ) files;
  end ;
  Buffer.contents b

let template_main_dune p =
  Printf.sprintf
    {|
(executable
 (name main)
 (public_name %s)
 (package %s)
 (libraries %s_lib))
|}
    p.name p.name p.name

let template_dune_project p =
  let b = Buffer.create 100000 in
  Printf.bprintf b
    {|(lang dune 2.0)
; This file was generated by drom, using drom.toml
(name %s)
(allow_approximate_merlin)
(generate_opam_files false)
(version %s)
|}
    p.package.name
    p.version ;

  Printf.bprintf b {|
(package
 (name %s)
 (synopsis %S)
 (description %S)
|}
    ( if p.kind = Both then p.package.name ^ "_lib" else p.package.name )
    ( if p.kind = Both then
        ( Misc.p_synopsis p.package ) ^ " (library)" else
        Misc.p_synopsis p.package )
    p.description ;
  Printf.bprintf b " (depends\n";
  Printf.bprintf b "   (ocaml (>= %s))\n" p.min_edition ;
  List.iter (fun (name, d) ->
      match Misc.semantic_version d.depversion with
      | Some (major, minor, fix) ->
        Printf.bprintf b "   (%s (and (>= %d.%d.%d) (< %d.0.0)))\n"
          name major minor fix (major+1)
      | None ->
        Printf.bprintf b "   (%s (>= %s))\n" name d.depversion
    ) ( Misc.p_dependencies p.package ) ;
  List.iter (fun (name, version) ->
      match Misc.semantic_version version with
      | Some (major, minor, fix) ->
        Printf.bprintf b "   (%s (and (>= %d.%d.%d) (< %d.0.0)))\n"
          name major minor fix (major+1)
      | None ->
        Printf.bprintf b "   (%s (>= %s))\n" name version
    ) ( Misc.p_tools p.package ) ;
  Printf.bprintf b " ))\n";

  if p.kind = Both then begin
    Printf.bprintf b {|
(package
 (name %s)
 (synopsis "%s")
 (description "%s")
 (depends (%s_lib (= version))))
|}
      p.package.name
      ( Misc.p_synopsis p.package )
      ( Misc.p_description p.package )
      p.package.name
      (*      ( Misc.p_version p.package ) *)
  end ;

  Buffer.contents b
