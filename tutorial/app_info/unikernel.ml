open Build_info.V1

let libraries = Statically_linked_libraries.to_list ()

let libraries =
  List.map
    (fun l ->
      let name = Statically_linked_library.name l in
      let version =
        match Statically_linked_library.version l with
        | None -> "n/a"
        | Some v -> Version.to_string v
      in
      (name, version))
    libraries

let pp_library ppf (name, version) = Fmt.pf ppf "%s.%s" name version

let start () =
  Fmt.pr "libraries:\n";
  List.iter (Fmt.pr "  - %a\n" pp_library) libraries;
  Lwt.return_unit
