(* Ocsigen-start
 * http://www.ocsigen.org/ocsigen-start
 *
 * Copyright (C) Université Paris Diderot, CNRS, INRIA, Be Sport.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

exception No_such_resource
exception Main_email_removal_attempt
exception Account_not_activated

let section = Lwt_log.Section.make "os:db"

let (>>=) = Lwt.bind

module Lwt_thread = struct
  include Lwt
  let close_in = Lwt_io.close
  let really_input = Lwt_io.read_into_exactly
  let input_binary_int = Lwt_io.BE.read_int
  let input_char = Lwt_io.read_char
  let output_string = Lwt_io.write
  let output_binary_int = Lwt_io.BE.write_int
  let output_char = Lwt_io.write_char
  let flush = Lwt_io.flush
  let open_connection x = Lwt_io.open_connection x
  type out_channel = Lwt_io.output_channel
  type in_channel = Lwt_io.input_channel
end
module Lwt_PGOCaml = PGOCaml_generic.Make(Lwt_thread)
module PGOCaml = Lwt_PGOCaml

let host_r = ref None
let port_r = ref None
let user_r = ref None
let password_r = ref None
let database_r = ref None
let unix_domain_socket_dir_r = ref None
let init_r = ref None

let connect () =
  lwt h =
    Lwt_PGOCaml.connect
    ?host:!host_r
    ?port:!port_r
    ?user:!user_r
    ?password:!password_r
    ?database:!database_r
    ?unix_domain_socket_dir:!unix_domain_socket_dir_r
    ()
  in
  match !init_r with
  | Some init ->
    lwt () = init h in
    Lwt.return h
  | None ->
    Lwt.return h

let validate db =
  try_lwt
    lwt () = Lwt_PGOCaml.ping db in
    Lwt.return_true
  with _ ->
    Lwt.return_false

let dispose db =
  Lwt.catch (fun () -> PGOCaml.close db) (fun _ -> Lwt.return_unit)

let pool : (string, bool) Hashtbl.t Lwt_PGOCaml.t Lwt_pool.t ref =
  ref @@ Lwt_pool.create 16 ~validate ~dispose connect

let set_pool_size n = pool := Lwt_pool.create n ~validate connect

let init ?host ?port ?user ?password ?database
         ?unix_domain_socket_dir ?pool_size ?init () =
  host_r := host;
  port_r := port;
  user_r := user;
  password_r := password;
  database_r := database;
  unix_domain_socket_dir_r := unix_domain_socket_dir;
  init_r := init;
  match pool_size with
  | None -> ()
  | Some n -> set_pool_size n

let connection_pool () = !pool

let use_pool f =
  Lwt_pool.use !pool @@ fun db ->
  try_lwt
    f db
  with
  | Lwt_PGOCaml.Error msg as e ->
    Lwt_log.ign_error_f ~section "postgresql protocol error: %s" msg;
    lwt () = Lwt_PGOCaml.close db in Lwt.fail e
  | Lwt.Canceled as e ->
    Lwt_log.ign_error ~section "thread canceled";
    lwt () = PGOCaml.close db in Lwt.fail e

let transaction_block db f =
  Lwt_PGOCaml.begin_work db >>= fun _ ->
  try_lwt
    lwt r = f () in
    lwt () = Lwt_PGOCaml.commit db in
    Lwt.return r
  with e ->
    lwt () =
      try_lwt
        Lwt_PGOCaml.rollback db
      with Lwt_PGOCaml.PostgreSQL_Error _ ->
        (* If the rollback fails, for instance due to a timeout,
           it seems better to close the connection. *)
        Lwt_log.ign_error ~section "rollback failed";
        Lwt_PGOCaml.close db
    in
    Lwt.fail e

let full_transaction_block f =
  use_pool (fun db -> transaction_block db (fun () -> f db))

let without_transaction = use_pool
