(*
 * Copyright (c) 2019 Jon Ludlam <jon@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(* Compatibility for older versions of OCaml *)

(* This module contains a subset of the types in ocaml.git/typing/types.ml from
   the latest version of the compiler. There is also conditionally compiled code
   for older versions of the compiler to convert from their version of types.ml
   to this version. This simplifies the support for older versions of OCaml.

   This is only done for the subsets of the types that contain the most invasive
   changes. For other simpler changes we use in-line cppo directives *)

type visibility =
  | Exported
  | Hidden

module Aliasability = struct
  type t = Not_aliasable | Aliasable
end

type module_type =
    Mty_ident of Path.t
  | Mty_signature of signature
  | Mty_functor of functor_parameter * module_type
  | Mty_alias of Path.t
  | Mty_strengthen of module_type * Path.t * Aliasability.t

and functor_parameter =
  | Unit
  | Named of Ident.t option * module_type

and module_presence =
  | Mp_present
  | Mp_absent

and signature = signature_item list

and signature_item =
    Sig_value of Ident.t * Types.value_description * visibility
  | Sig_type of Ident.t * Types.type_declaration * Types.rec_status * visibility
  | Sig_typext of Ident.t * Types.extension_constructor * Types.ext_status * visibility
  | Sig_module of
      Ident.t * module_presence * module_declaration * Types.rec_status * visibility
  | Sig_modtype of Ident.t * modtype_declaration * visibility
  | Sig_class of Ident.t * Types.class_declaration * Types.rec_status * visibility
  | Sig_class_type of Ident.t * Types.class_type_declaration * Types.rec_status * visibility

and module_declaration =
  {
    md_type: module_type;
    md_attributes: Parsetree.attributes;
    md_loc: Location.t;
  }

and modtype_declaration =
  {
    mtd_type: module_type option;  (* Note: abstract *)
    mtd_attributes: Parsetree.attributes;
    mtd_loc: Location.t;
  }


let opt conv = function | None -> None | Some x -> Some (conv x)

#if OCAML_VERSION >= (4,10,0)

let rec signature : Types.signature -> signature = fun x -> List.map signature_item x

and signature_item : Types.signature_item -> signature_item = function
  | Types.Sig_value (a,b,c) -> Sig_value (a,b,visibility c)
  | Types.Sig_type (a,b,c,d) -> Sig_type (a,b,c, visibility d)
  | Types.Sig_typext (a,b,c,d) -> Sig_typext (a,b,c,visibility d)
  | Types.Sig_module (a,b,c,d,e) -> Sig_module (a, module_presence b, module_declaration c, d, visibility e)
  | Types.Sig_modtype (a,b,c) -> Sig_modtype (a, modtype_declaration b, visibility c)
  | Types.Sig_class (a,b,c,d) -> Sig_class (a,b,c, visibility d)
  | Types.Sig_class_type (a,b,c,d) -> Sig_class_type (a,b,c, visibility d)

and visibility : Types.visibility -> visibility = function
  | Types.Hidden -> Hidden
  | Types.Exported -> Exported

and aliasability : Types.Aliasability.t -> Aliasability.t = function
  | Types.Aliasability.Not_aliasable -> Aliasability.Not_aliasable
  | Types.Aliasability.Aliasable -> Aliasability.Aliasable

and module_type : Types.module_type -> module_type = function
  | Types.Mty_ident p -> Mty_ident p
  | Types.Mty_signature s -> Mty_signature (signature s)
  | Types.Mty_functor (a, b) -> Mty_functor(functor_parameter a, module_type b)
  | Types.Mty_alias p -> Mty_alias p
  | Types.Mty_strengthen (mty,p,a) ->
      Mty_strengthen (module_type mty, p, aliasability a)

and functor_parameter : Types.functor_parameter -> functor_parameter = function
  | Types.Unit -> Unit
  | Types.Named (a,b) -> Named (a, module_type b)

and module_presence : Types.module_presence -> module_presence = function
  | Types.Mp_present -> Mp_present
  | Types.Mp_absent -> Mp_absent

and module_declaration : Types.module_declaration -> module_declaration = fun x ->
  { md_type = module_type x.Types.md_type;
    md_attributes = x.md_attributes;
    md_loc = x.md_loc }

and modtype_declaration : Types.modtype_declaration -> modtype_declaration = fun x ->
  { mtd_type = opt module_type x.Types.mtd_type;
    mtd_attributes = x.Types.mtd_attributes;
    mtd_loc = x.Types.mtd_loc }

#elif OCAML_VERSION >= (4,8,0)

let rec signature : Types.signature -> signature = fun x -> List.map signature_item x

and signature_item : Types.signature_item -> signature_item = function
  | Types.Sig_value (a,b,c) -> Sig_value (a,b,visibility c)
  | Types.Sig_type (a,b,c,d) -> Sig_type (a,b,c, visibility d)
  | Types.Sig_typext (a,b,c,d) -> Sig_typext (a,b,c,visibility d)
  | Types.Sig_module (a,b,c,d,e) -> Sig_module (a, module_presence b, module_declaration c, d, visibility e)
  | Types.Sig_modtype (a,b,c) -> Sig_modtype (a, modtype_declaration b, visibility c)
  | Types.Sig_class (a,b,c,d) -> Sig_class (a,b,c, visibility d)
  | Types.Sig_class_type (a,b,c,d) -> Sig_class_type (a,b,c, visibility d)

and visibility : Types.visibility -> visibility = function
  | Types.Hidden -> Hidden
  | Types.Exported -> Exported

and module_type : Types.module_type -> module_type = function
  | Types.Mty_ident p -> Mty_ident p
  | Types.Mty_signature s -> Mty_signature (signature s)
  | Types.Mty_functor (a, b, c) -> begin
    match b with
    | Some m -> Mty_functor(Named(Some a,module_type m),module_type c)
    | None -> Mty_functor(Unit,module_type c)
    end
  | Types.Mty_alias p -> Mty_alias p

and module_presence : Types.module_presence -> module_presence = function
  | Types.Mp_present -> Mp_present
  | Types.Mp_absent -> Mp_absent

and module_declaration : Types.module_declaration -> module_declaration = fun x ->
  { md_type = module_type x.Types.md_type;
    md_attributes = x.md_attributes;
    md_loc = x.md_loc }

and modtype_declaration : Types.modtype_declaration -> modtype_declaration = fun x ->
  { mtd_type = opt module_type x.Types.mtd_type;
    mtd_attributes = x.Types.mtd_attributes;
    mtd_loc = x.Types.mtd_loc }

#elif OCAML_VERSION >= (4,4,0) && OCAML_VERSION < (4,8,0)

  let rec module_type : Types.module_type -> module_type = function
  | Types.Mty_ident p -> Mty_ident p
  | Types.Mty_signature s -> Mty_signature (signature s)
  | Types.Mty_functor (a, b, c) -> begin
    match b with
    | Some m -> Mty_functor(Named(Some a,module_type m),module_type c)
    | None -> Mty_functor(Unit,module_type c)
    end
  | Types.Mty_alias (_,q) -> Mty_alias q

  and signature_item : Types.signature_item -> signature_item = function
  | Types.Sig_value (id, d) -> Sig_value (id, d, Exported)
  | Types.Sig_type (id, td, rec_status) -> Sig_type (id, td, rec_status, Exported)
  | Types.Sig_typext (id, ec, es) -> Sig_typext (id, ec, es, Exported)
  | Types.Sig_module (id, ({md_type = Types.Mty_alias (Types.Mta_present, _); _} as md), rs) -> Sig_module (id, Mp_present, module_declaration md, rs, Exported)
  | Types.Sig_module (id, ({md_type = Types.Mty_alias (Types.Mta_absent, _); _} as md), rs) -> Sig_module (id, Mp_absent, module_declaration md, rs, Exported)
  | Types.Sig_module (id, md, rs) -> Sig_module (id, Mp_present, module_declaration md, rs, Exported)
  | Types.Sig_modtype (id, mtd) -> Sig_modtype (id, modtype_declaration mtd, Exported)
  | Types.Sig_class (id, cd, rs) -> Sig_class (id, cd, rs, Exported)
  | Types.Sig_class_type (id, ctd, rs) -> Sig_class_type (id, ctd, rs, Exported)

  and signature : Types.signature -> signature = fun x -> List.map signature_item x

  and module_declaration : Types.module_declaration -> module_declaration = fun x ->
    { md_type = module_type x.Types.md_type;
      md_attributes = x.Types.md_attributes;
      md_loc = x.Types.md_loc }

  and modtype_declaration : Types.modtype_declaration -> modtype_declaration = fun x ->
    { mtd_type = opt module_type x.Types.mtd_type;
      mtd_attributes = x.Types.mtd_attributes;
      mtd_loc = x.Types.mtd_loc }

#elif OCAML_VERSION >= (4,2,0) && OCAML_VERSION < (4,4,0)

  let rec module_type : Types.module_type -> module_type = function
  | Types.Mty_ident p -> Mty_ident p
  | Types.Mty_signature s -> Mty_signature (signature s)
  | Types.Mty_functor (a, b, c) -> begin
    match b with
    | Some m -> Mty_functor(Named(Some a,module_type m),module_type c)
    | None -> Mty_functor(Unit,module_type c)
    end
  | Types.Mty_alias q -> Mty_alias q

  and signature_item : Types.signature_item -> signature_item = function
  | Types.Sig_value (id, d) -> Sig_value (id, d, Exported)
  | Types.Sig_type (id, td, rec_status) -> Sig_type (id, td, rec_status, Exported)
  | Types.Sig_typext (id, ec, es) -> Sig_typext (id, ec, es, Exported)
  | Types.Sig_module (id, md, rs) -> Sig_module (id, Mp_present, module_declaration md, rs, Exported)
  | Types.Sig_modtype (id, mtd) -> Sig_modtype (id, modtype_declaration mtd, Exported)
  | Types.Sig_class (id, cd, rs) -> Sig_class (id, cd, rs, Exported)
  | Types.Sig_class_type (id, ctd, rs) -> Sig_class_type (id, ctd, rs, Exported)

  and signature : Types.signature -> signature = fun x -> List.map signature_item x

  and module_declaration : Types.module_declaration -> module_declaration = fun x ->
    { md_type = module_type x.Types.md_type;
      md_attributes = x.Types.md_attributes;
      md_loc = x.Types.md_loc }

  and modtype_declaration : Types.modtype_declaration -> modtype_declaration = fun x ->
    { mtd_type = opt module_type x.Types.mtd_type;
      mtd_attributes = x.Types.mtd_attributes;
      mtd_loc = x.Types.mtd_loc }


#endif

(* Shapes were introduced in OCaml 4.14.0. They're used for resolving to source-code
   locations *)
#if OCAML_VERSION >= (4,14,0)

type shape = Shape.t

type 'a shape_uid_map = 'a Shape.Uid.Map.t

type uid_to_loc = Warnings.loc Types.Uid.Tbl.t
let empty_map = Shape.Uid.Map.empty

#if OCAML_VERSION < (5,2,0)
let shape_info_of_cmt_infos : Cmt_format.cmt_infos -> (shape * uid_to_loc) option =
 fun x -> Option.map (fun s -> (s, x.cmt_uid_to_loc)) x.cmt_impl_shape
#else

let shape_info_of_cmt_infos : Cmt_format.cmt_infos -> (shape * uid_to_loc) option =
  let loc_of_declaration =
    let open Typedtree in
    function
    | Value v -> v.val_loc
    | Value_binding vb -> vb.vb_pat.pat_loc
    | Type t -> t.typ_loc
    | Constructor c -> c.cd_loc
    | Extension_constructor e -> e.ext_loc
    | Label l -> l.ld_loc
    | Module m -> m.md_loc
    | Module_substitution ms -> ms.ms_loc
    | Module_binding mb -> mb.mb_loc
    | Module_type mt -> mt.mtd_loc
    | Class cd -> cd.ci_id_name.loc
    | Class_type ctd -> ctd.ci_id_name.loc
  in
  fun x -> Option.map (fun s -> (s, Shape.Uid.Tbl.map x.cmt_uid_to_decl loc_of_declaration)) x.cmt_impl_shape
#endif

#else

type shape = unit

type 'a shape_uid_map = unit

type uid_to_loc = unit
let empty_map = ()

let shape_info_of_cmt_infos : Cmt_format.cmt_infos -> (shape * uid_to_loc) option = fun _ -> None

#endif

#if OCAML_VERSION >= (5,2,0)
let compunit_name : Compilation_unit.t -> string = Compilation_unit.name_as_string

let required_compunit_names x = List.map compunit_name x.Cmo_format.cu_required_compunits

#elif OCAML_VERSION >= (4,04,0)

let compunit_name x = Compilation_unit.name_as_string x

let required_compunit_names x = List.map compunit_name x.Cmo_format.cu_required_globals

#else

  let compunit_name x = x
  let required_compunit_names x = List.map fst x.Cmo_format.cu_imports

#endif
