{shared{
  open Eliom_content.Html5
  open Eliom_content.Html5.F
  open %%%MODULE_NAME%%%_tools
}}

let header ?user () =
  lwt user_box =
    match user with
      | None -> Lwt.return (nothing ())
      | Some user ->
        lwt username = %%%MODULE_NAME%%%_view.username user in
        Lwt.return (div ~a:[a_id "%%%PROJECT_NAME%%%-user-box"] [
                      %%%MODULE_NAME%%%_view.avatar user;
                      username;
                      %%%MODULE_NAME%%%_view.disconnect_button ();
                    ])
  in
  Lwt.return
    (div ~a:[a_id "%%%PROJECT_NAME%%%-header"] [
      a ~a:[a_id "%%%PROJECT_NAME%%%-logo"]
        ~service:%%%MODULE_NAME%%%_services.main_service [
          pcdata Ebapp.App.app_name;
        ] ();
      div ~a:[a_id "%%%PROJECT_NAME%%%-navbar"]
        [
          a ~a:[a_class ["item"; "eba-box"]]
            ~service:%%%MODULE_NAME%%%_services.main_service [
              pcdata "Home";
            ] ();
          a ~a:[a_class ["item"; "eba-box"]]
            ~service:%%%MODULE_NAME%%%_services.about_service [
              pcdata "About";
            ] ();
        ];
      user_box;
    ])

let footer ?user () =
  div ~a:[a_id "%%%PROJECT_NAME%%%-footer"] [
    span ~a:[a_class ["eba-template"]] [
      pcdata "This application has been generated using the ";
      a ~service:%%%MODULE_NAME%%%_services.eba_github_service [
        pcdata "Eliom-base-app"
      ] ();
      pcdata " template for Eliom-distillery and uses the ";
      a ~service:%%%MODULE_NAME%%%_services.ocsigen_service [
        pcdata "Ocsigen"
      ] ();
      pcdata " technology.";
    ];
  ]

let page ?user cnt =
  let l =
    [ div ~a:[a_id "%%%PROJECT_NAME%%%-body"]
        (div ~a:[a_id "%%%PROJECT_NAME%%%-request-msgs"]
           ( (List.map (Ebapp.Reqm.to_html)
                (Ebapp.Reqm.to_list %%%MODULE_NAME%%%_reqm.notice_set))
             @ (List.map (Ebapp.Reqm.to_html)
                  (Ebapp.Reqm.to_list %%%MODULE_NAME%%%_reqm.error_set)))
         ::cnt);
      footer ?user ();
    ]
  in
  lwt h = header ?user () in
  Lwt.return (h
              ::match user with
                | Some user when (user.%%%MODULE_NAME%%%_user.fn = ""
                                 || user.%%%MODULE_NAME%%%_user.ln = "") ->
                  %%%MODULE_NAME%%%_view.information_form () :: l
                | _ -> l)
