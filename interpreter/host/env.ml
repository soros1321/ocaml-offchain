(*
 * Emulation of (a subset of) the `env` module currently used by Binaryen,
 * so that we can run modules generated by Binaryen. This is a stopgap until
 * we have agreement on what libc should look like.
 *)

open Values
open Types
open Instance


let error msg = raise (Eval.Crash (Source.no_region, msg))

let type_error v t =
  error
    ("type error, expected " ^ string_of_value_type t ^
     ", got " ^ string_of_value_type (type_of v))

let empty = function
  | [] -> ()
  | vs -> error "type error, too many arguments"

let single = function
  | [] -> error "type error, missing arguments"
  | [v] -> v
  | vs -> error "type error, too many arguments"

let int = function
  | I32 i -> Int32.to_int i
  | v -> type_error v I32Type


let abort vs =
  empty vs;
  print_endline "Abort!";
  exit (-1)

let exit vs =
  exit (int (single vs))

let lookup name t =
  match Utf8.encode name, t with
  | "abort", ExternalFuncType t -> ExternalFunc (HostFunc (t, abort))
  | "exit", ExternalFuncType t -> ExternalFunc (HostFunc (t, exit))
  | "STACKTOP", ExternalGlobalType t -> ExternalGlobal (I32 0l)
  | "DYNAMICTOP_PTR", ExternalGlobalType t -> ExternalGlobal (I32 0l)
  | "STACK_MAX", ExternalGlobalType t -> ExternalGlobal (I32 1024l)
  | "tempDoublePtr", ExternalGlobalType t -> ExternalGlobal (I32 0l)
  | "ABORT", ExternalGlobalType t -> ExternalGlobal (I32 0l)
  | "memoryBase", ExternalGlobalType t -> ExternalGlobal (I32 0l)
  | "tableBase", ExternalGlobalType t -> ExternalGlobal (I32 0l)
  | _, ExternalFuncType t -> ExternalFunc (HostFunc (t, abort))
  | "memory", ExternalMemoryType (MemoryType {min;max}) ->
    ExternalMemory (Memory.create {min;max})
  | "table", ExternalTableType (TableType ({min;max}, t)) -> ExternalTable (Table.create t {min;max})
  | _ -> raise Not_found


