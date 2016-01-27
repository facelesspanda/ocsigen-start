(* This file was generated by Eliom-base-app.
   Feel free to use it, modify it, and redistribute it as you wish. *)

(** Connexion box, box with connected user information and menu *)

[%%shared.start]

  type uploader = unit Ow_pic_uploader.t



[%%server.start]
  val uploader : string list -> uploader



[%%shared.start]

 (** Box for connected users, with picture, name, and menu *)
val connected_user_box :
  Eba_user.t -> uploader -> [> Html5_types.div ] Eliom_content.Html5.D.elt

(** Connection box *)
val connection_box :
  unit -> [> Html5_types.div ] Eliom_content.Html5.D.elt Lwt.t

(** Connected user box or connexion box, depending whether user
    is connected or not *)
val userbox :
  Eba_user.t option ->
  uploader ->
  [> Html5_types.div ] Eliom_content.Html5.D.elt Lwt.t

(** Link to upload a picture.
    The client function given as first parameter will be called first,
    for example to close the menu containing the link. *)
val upload_pic_link :
  ?a:[< Html5_types.a_attrib ] Eliom_content.Html5.D.Raw.attrib list ->
  ?content:Html5_types.a_content Eliom_content.Html5.D.Raw.elt list ->
  (unit -> unit) Eliom_pervasives.client_value ->
  uploader -> [> `A of Html5_types.a_content ] Eliom_content.Html5.D.Raw.elt

(** Link to start to see the help from the begining.
    The client function given as first parameter will be called first,
    for example to close the menu containing the link. *)
val reset_tips_link :
  (unit -> unit) Eliom_pervasives.client_value ->
  [> `A of [> `PCDATA ] ] Eliom_content.Html5.D.Raw.elt

(** Display user menu *)
val user_menu :
  Eba_user.t ->
  uploader -> [> Html5_types.div ] Eliom_content.Html5.F.elt


[%%client.start]

(** Personnalize user menu *)
val set_user_menu :
  ((unit -> unit) ->
   Eba_user.t ->
   uploader ->
   Html5_types.div_content Eliom_content.Html5.D.elt
     Eliom_content.Html5.D.list_wrap) ->
  unit



[%%server.start]
  val wrong_password : bool Eliom_reference.Volatile.eref
  val user_already_exists : bool Eliom_reference.Volatile.eref
  val user_does_not_exist : bool Eliom_reference.Volatile.eref
  val user_already_preregistered : bool Eliom_reference.Volatile.eref
  val activation_key_outdated : bool Eliom_reference.Volatile.eref
