Require Import ssreflect ssrfun ssrbool eqtype ssrnat choice fintype seq.
Require Import div ssralg finalg zmodp bigop tuple.
Require Import BinNums.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section Def.

Variable k : nat.

CoInductive word : predArgType := Word of 'I_(2 ^ k).

Definition ord_of_word (w : word) := let: Word i := w in i.

Canonical word_subType := [newType for ord_of_word].
Definition word_eqMixin := [eqMixin of word by <:].
Canonical word_eqType := Eval hnf in EqType word word_eqMixin.
Definition word_choiceMixin := [choiceMixin of word by <:].
Canonical word_choiceType := Eval hnf in ChoiceType word word_choiceMixin.
Definition word_countMixin := [countMixin of word by <:].
Canonical word_countType := Eval hnf in CountType word word_countMixin.
Canonical word_subCountType := Eval hnf in [subCountType of word].
Definition word_finMixin := [finMixin of word by <:].
Canonical word_finType := Eval hnf in FinType word word_finMixin.
Canonical word_subFinType := Eval hnf in [subFinType of word].

Lemma card_word : #|{: word}| = 2 ^ k.
Proof. by rewrite card_sub eq_cardT // -cardT card_ord. Qed.

Lemma exp2_gt0 : 0 < 2 ^ k.
Proof. by rewrite expn_gt0. Qed.

Definition as_word (n : nat) := Word (Ordinal (ltn_pmod n exp2_gt0)).

Definition addw (w1 w2 : word) := as_word (val w1 + val w2).
Definition oppw (w : word) := as_word (2 ^ k - val w).
Definition mulw (w1 w2 : word) := as_word (val w1 * val w2).

Definition zerow := as_word 0.
Definition onew := as_word 1.

Lemma valwK (w : word) : as_word (val w) = w.
Proof. by apply: val_inj; apply: val_inj; rewrite /= modn_small. Qed.

Lemma add0w : left_id zerow addw.
Proof. by move=> w; rewrite /addw /= mod0n valwK. Qed.

Lemma addNw : left_inverse zerow oppw addw.
Proof.
  by move=> w; do 2!apply: val_inj;
  rewrite /= modnDml subnK ?modnn ?mod0n // ltnW.
Qed.

Lemma addwA : associative addw.
Proof.
by move=> x y z; do 2!apply: val_inj; rewrite /= modnDml modnDmr addnA.
Qed.

Lemma addwC : commutative addw.
Proof. by move=> x y; do 2!apply: val_inj; rewrite /= addnC. Qed.

Definition word_zmodMixin := ZmodMixin addwA addwC add0w addNw.
Canonical word_zmodType := ZmodType word word_zmodMixin.
Canonical word_finZmodType := Eval hnf in [finZmodType of word].
Canonical word_baseFinGroupType := Eval hnf in [baseFinGroupType of word for +%R].
Canonical word_finGroupType := Eval hnf in [finGroupType of word for +%R].

Lemma mul1w : left_id onew mulw.
Proof.
  by move=> w; do 2!apply: val_inj; rewrite /= /mulw modnMml mul1n modn_small.
Qed.

Lemma mulwC : commutative mulw.
Proof. by move=> w1 w2; rewrite /mulw mulnC. Qed.

Lemma mulw1 : right_id onew mulw.
Proof. by move=> w; rewrite mulwC mul1w. Qed.

Lemma mulwA : associative mulw.
Proof.
  move=> w1 w2 w3; do 2!apply: val_inj.
  by rewrite /= /mulw modnMml modnMmr mulnA.
Qed.

Lemma mulw_addr : right_distributive mulw addw.
Proof.
  move=> w1 w2 w3; do 2!apply: val_inj.
  by rewrite /= /mulw modnMmr modnDm mulnDr.
Qed.

Lemma mulw_addl : left_distributive mulw addw.
Proof.
  by move=> w1 w2 w3; rewrite -!(mulwC w3) mulw_addr.
Qed.

Definition digit_of_nat b k n : 'I_b.+1:=
  inZp (n %/ b.+1 ^ k).

Definition digits_of_nat b k n :=
  [tuple of mkseq (fun i => digit_of_nat b i n) k].

Definition nat_of_digits b ds :=
  \sum_(i < size ds) nth 0 ds i * b.+1 ^ i.

Lemma nat_of_digits_digits_of_nat b n k :
  nat_of_digits b [seq val i | i <- digits_of_nat b k n] = n %% b.+1 ^ k.
Proof.
  rewrite /nat_of_digits /digits_of_nat size_map /= size_mkseq
          (eq_big_seq (fun i : 'I_k => digit_of_nat b i n * b.+1 ^ i)); last first.
    by move=> i _ /=; rewrite (nth_map ord0) ?size_mkseq //= nth_mkseq /=.
  elim: k => [|k IH] /=.
    by rewrite big_ord0 expn0 modn1.
  rewrite big_ord_recr {}IH /digit_of_nat /=.
  rewrite {1}(divn_eq n (b.+1 ^ k.+1)) {2}expnS mulnA modnMDl.
  suff -> : (n %/ b.+1 ^ k) %% b.+1 = (n %% b.+1 ^ k.+1) %/ b.+1 ^ k.
    by rewrite addnC -divn_eq.
  by rewrite {1}(divn_eq n (b.+1 ^ k.+1)) {2}expnS mulnA divnMDl ?expn_gt0 //
             modnMDl modn_small // ltn_divLR ?expn_gt0 // -expnS ltn_mod
             expn_gt0.
Qed.

Definition digits_of_ord b k (n : 'I_(b.+1 ^ k)) := digits_of_nat b k n.

Lemma digits_of_ord_bij b k : bijective (@digits_of_ord b k).
Proof.
  apply: inj_card_bij.
    move=> n1 n2 /= H.
    move: (nat_of_digits_digits_of_nat b n1 k)
          (nat_of_digits_digits_of_nat b n2 k).
    rewrite /digits_of_ord in H.
    rewrite {}H !modn_small //= => ->.
    by apply val_inj.
  by rewrite card_tuple !card_ord.
Qed.

Lemma nat_of_digits_bounds b (ds : seq 'I_b.+1) :
  nat_of_digits b [seq val i | i <- ds] < b.+1 ^ size ds.
Proof.
  rewrite -{1}[ds]/(val (@Tuple _ _ ds (eqxx (size ds)))).
  move: (size ds) (Tuple _) => {ds} k ds.
  have [inv H1 H2] := digits_of_ord_bij b k.
  by rewrite -(H2 ds) nat_of_digits_digits_of_nat ltn_mod expn_gt0.
Qed.

Lemma ord_of_digits_proof b k (ds : k.-tuple 'I_b.+1) :
  nat_of_digits b [seq val i | i <- ds] < b.+1 ^ k.
Proof.
  move: (nat_of_digits_bounds ds). by rewrite size_tuple.
Qed.

Definition ord_of_digits b k ds := Ordinal (@ord_of_digits_proof b k ds).

Lemma digits_of_ordK b k : cancel (@digits_of_ord b k) (@ord_of_digits b k).
Proof.
  move=> n; apply: val_inj.
  by rewrite /ord_of_digits /digits_of_ord /=
             nat_of_digits_digits_of_nat modn_small.
Qed.

Lemma ord_of_digitsK b k : cancel (@ord_of_digits b k) (@digits_of_ord b k).
Proof.
  have Hbij := digits_of_ord_bij b k.
  have [inv H1 H2] := Hbij.
  have Heq := bij_can_eq Hbij (@digits_of_ordK b k) H1.
  by apply: eq_can H2 (fsym Heq) (frefl _).
Qed.





Definition bits_of_ord k (n : 'I_(2 ^ k)) :=
  [tuple of [seq 0 < val d | d <- digits_of_ord n]].

Definition ord_of_bits k (bs : k.-tuple bool) : 'I_(2 ^ k) :=
  ord_of_digits [tuple of [seq inZp b | b : bool <- bs]].

Lemma bits_of_ordK k : cancel (@bits_of_ord k) (@ord_of_bits k).
Proof.
  have Hcan : cancel (fun n : 'I_2 => 0 < n) (fun b : bool => inZp b).
    by move=> n; apply: val_inj; move: n => [[|[|]]].
  move=> n. apply: val_inj => /=.
  by rewrite (mapK Hcan) -{2}(digits_of_ordK n).
Qed.

Lemma ord_of_bitsK k : cancel (@ord_of_bits k) (@bits_of_ord k).
Proof.
  have Hcan : cancel (fun b : bool => inZp b) (fun n : 'I_2 => 0 < n) by case.
  move=> n. apply: val_inj.
  by rewrite /bits_of_ord /ord_of_bits ord_of_digitsK /= (mapK Hcan).
Qed.

Section Def.

Variable n : nat.

CoInductive word := Word of n.-tuple bool.

Bind Scope word_scope with word.
Delimit Scope word_scope with w.

Local Open Scope word_scope.

Definition bits (w : word) := let: Word w := w in w.

Local Coercion bits : word >-> tuple_of.

Lemma bitsK : cancel bits Word.
Proof. by case. Qed.

Lemma bits_inj : injective bits.
Proof. exact: can_inj bitsK. Qed.

Fixpoint add_aux b (w1 w2 : seq bool) : seq bool :=
  match w1, w2 with
  | [::], [::] => [::]
  | b1 :: w1, b2 :: w2 =>
    b (+) b1 (+) b2 :: add_aux (2 <= b + b1 + b2) w1 w2
  | _, _ => [::]
  end.

Lemma size_add_aux c (w1 w2 : word) : size (add_aux c w1 w2) == n.
Proof.
  suff -> : size (add_aux c w1 w2) = minn (size w1) (size w2).
    by rewrite !size_tuple minnn.
  elim: {w1 w2} (w1 : seq bool) (w2 : seq bool) c
        => [|b1 w1 IH] [|b2 w2] c //=.
  by rewrite minnSS IH.
Qed.

Definition addw (w1 w2 : word) := Word (Tuple (size_add_aux false w1 w2)).

Notation "x + y" := (addw x y) : word_scope.

Lemma addwC : commutative addw.
Proof.
  move=> w1 w2.
  apply: bits_inj. apply: val_inj => //=.
  elim: {w1 w2} (w1 : seq bool) (w2 : seq bool) false => [|b1 w1 IH] [|b2 w2] b //=.
  by rewrite -addbA (addbC b1) addbA
             -addnA (addnC b1) addnA IH.
Qed.

Lemma addwA : associative addw.
Proof.
  move=> w1 w2 w3.
  apply: bits_inj; apply: val_inj=> //=.
  elim: {w1 w2 w3} (w1 : seq bool) (w2 : seq bool) (w3 : seq bool)
        false {1 3}false {1 4}false {1 5}false
        (erefl (false + false)%nat)
        => [|b1 w1 IH] [|b2 w2] [|b3 w3] c4 c3 c2 c1 Hc //=.
  rewrite 2!addbA -(addbA c1 b1) (addbC b1) ![in X in X :: _ = _]addbA
          ![in X in _ = X :: _]addbA.
  have -> : c1 (+) c2 = c3 (+) c4.
    by case: c1 c2 c3 c4 Hc => [] [] [] [].
  congr cons.
  apply: IH.
  move: b1 b2 b3 c1 c2 c3 c4 Hc.
  by do !case=> //.
Qed.

Definition zerow := Word [tuple of nseq n false].
Definition onew := Word [tuple of mkseq (pred1 0) n].
Definition minusonew := Word [tuple of nseq n true].

Lemma eqw01 : (zerow == onew) = (n == 0).
Proof.
  rewrite -(inj_eq bits_inj) -val_eqE /=.
  by case: n => [|n'] //.
Qed.

Lemma add0w : left_id zerow addw.
Proof.
  move=> w.
  apply: bits_inj; apply: val_inj=> /=.
  elim: {w} (w : seq bool) {2 3}n (size_tuple w) => [|b w IH] [|n'] //= [H].
  have E : 1 < b = false by case: b.
  by rewrite !add0n {}E IH.
Qed.

Lemma addw0 : right_id zerow addw.
Proof. by move=> w; rewrite addwC add0w. Qed.

Definition oppw (w : word) :=
  addw onew (Word [tuple of map negb w]).

Lemma addNw : left_inverse zerow oppw addw.
Proof.
  move=> w.
  apply: bits_inj; apply: val_inj => /=.
  case: n (w : seq bool) (size_tuple w) => {w} [|n'] [|b w] //= [E].
  rewrite negbK addbb !add0n addnn; congr cons.
  have -> : 1 < b.*2 = b by case: b.
  have -> : 1 < 1 + ~~ b = ~~ b by case: b.
  elim: w {2}0 b n' E => [|b' w IH] n0 b [|n'] //= [/IH E] {IH}.
  rewrite eqE /= addbF !addbA (addbN b) addbb /= negbK addbb addn0; congr cons.
  have -> : 1 < ~~ b + ~~ b' = ~~ (b || b') by case: b b' => [] [].
  have -> : 1 < b + (~~ b (+) ~~ b') + b' = b || b' by case: b b' => [] [].
  by rewrite E.
Qed.

Lemma addwN : right_inverse zerow oppw addw.
Proof. by move=> w; rewrite addwC addNw. Qed.

Definition subw w1 w2 := w1 + oppw w2.

Definition bitwise op (w1 w2 : word) :=
  Word [tuple of map (fun p => op p.1 p.2) (zip w1 w2)].

Lemma bitwiseC op : commutative op -> commutative (bitwise op).
Proof.
  move=> opC w1 w2.
  apply: bits_inj; apply: val_inj => //=.
  elim: {w1 w2} (w1 : seq bool) (w2 : seq bool) => [|b1 w1 IH] [|b2 w2] //=.
  by rewrite IH opC.
Qed.

Lemma bitwiseA op : associative op -> associative (bitwise op).
Proof.
  move=> opA w1 w2 w3.
  apply: bits_inj; apply: val_inj => /=.
  elim: {w1 w2 w3} (w1 : seq bool) (w2 : seq bool) (w3 : seq bool)
        => [|b1 w1 IH] [|b2 w2] [|b3 w3] //=.
  by rewrite IH opA.
Qed.

Definition andw := bitwise andb.
Lemma andwC : commutative andw.
Proof. exact: bitwiseC andbC. Qed.
Lemma andwA : associative andw.
Proof. exact: bitwiseA andbA. Qed.

Definition orw := bitwise orb.
Lemma orwC : commutative orw.
Proof. exact: bitwiseC orbC. Qed.
Lemma orwA : associative orw.
Proof. exact: bitwiseA orbA. Qed.

Definition xorw := bitwise addb.
Lemma xorwC : commutative xorw.
Proof. exact: bitwiseC addbC. Qed.
Lemma xorwA : associative xorw.
Proof. exact: bitwiseA addbA. Qed.

Definition nat_of_word (w : word) :=
  \sum_(i < n) tnth w i * 2 ^ i.

Fixpoint word_of_nat (n : nat) :=
  if n is n.+1 then onew + word_of_nat n
  else zerow.

Lemma addw_addn : morphism_2 nat_of_word addw addn.
Proof.
  move=> w1 w2.
  rewrite /addw /nat_of_word /= -big_split /=.

  have : forall t, tnth
  have := (eq_big_seq _ (fun x _ => tnth_nth false w1 x)).

Lemma nat_of_wordK : cancel nat_of_word word_of_nat.
Proof. move=> w.



End Def.

Section Mul.



Definition mulw (w1 w2 : word) :=
  mul_aux w1 w2 zerow.

Lemma mulwC : commutative mulw.



End Def.

Section Pos.

Variable n : nat.

Local Coercion bits : word >-> tuple_of.

Definition onew : word n.+1 := Word [tuple of true :: nseq n false].

Definition oppw (w : word n.+1) :=
  addw onew (Word [tuple of map negb w]).

Lemma oppwK : left_inverse zerow oppw addw



Definition casen (n : N) : option (bool * N) :=
  if n is Npos p then
    match p with
    | xI p => Some (true, Npos p)
    | xO p => Some (false, Npos p)
    | xH => Some (true, N0)
    end
  else None.

Definition consn (b : bool) (n : N) : N :=
  if b then
    if n is Npos p then Npos (xI p)
    else Npos xH
  else
    if n is Npos p then Npos (xO p)
    else N0.

Fixpoint sizep (p : positive) : nat :=
  match p with
  | xI p
  | xO p => (sizep p).+1
  | xH => 0
  end.

Definition sizen (n : N) : nat :=
  if n is Npos p then (sizep p).+1
  else 0.

Fixpoint truncaten s n :=
  if s is s.+1 then
    if n is Npos p then
      match p with
      | xI p => if truncaten s (Npos p) is Npos p' then Npos (xI p')
                else Npos xH
      | xO p => if truncaten s (Npos p) is Npos p' then Npos (xO p')
                else N0
      | xH => Npos xH
      end
    else N0
  else N0.

Lemma sizen_truncate s n :
  sizen (truncaten s n) <= s.
Proof.
  elim: s n => [|s IH] [|[p|p|]] //=.
    by case: {IH p} (truncaten s (Npos p)) (IH (Npos p)) => [|p] //.
  by case: {IH p} (truncaten s (Npos p)) (IH (Npos p)) => [|p] //.
Qed.

Fixpoint inc s n : N :=
  if s is s.+1 then
    if casen n is Some (b, n') then
      if b then consn false (inc s n')
      else consn true n'
    else 1%N
  else N0.

Lemma sizen_inc s n :
  sizen n <= s ->
  sizen (inc s n) <= s.
Proof.
  elim: s n => [|s IH] [|[p|p|]] //.
    move=> /(IH (Npos p)) {IH} /=.
    by case: (inc s _).
  by case s.
Qed.

Definition addc s c n : N :=
  if c then inc s n else n.

Lemma addc_cons s c b n :
  addc s.+1 c (consn b n) =
  consn (c (+) b) (addc s (c && b) n).
Proof.
  case: c => //=.
  by case: b n => [] [|[p|p|]] //.
Qed.

Lemma sizen_addc s c n :
  sizen n <= s ->
  sizen (addc s c n) <= s.
Proof.
  case: c => //=.
  exact: sizen_inc.
Qed.

Fixpoint add_aux s c n m : N :=
  if s is s'.+1 then
    match casen n, casen m with
    | Some (bn, n), Some (bm, m) =>
      consn (c (+) bn (+) bm) (add_aux s' (2 <= c + bn + bm) n m)
    | Some _, None => addc s c n
    | None, Some _ => addc s c m
    | None, None => if c then Npos xH else N0
    end
  else N0.

Definition add s n m : N :=
  add_aux s false n m.

Fixpoint add' s n m : N :=
  if s is s.+1 then
    match casen n, casen m with
    | None, _ => m
    | Some _, None => n
    | Some (bn, n), Some (bm, m) =>
      consn (bn (+) bm) (addc s (bn && bm) (add' s n m))
    end
  else N0.

Lemma add_auxE s c n m :
  add_aux s c n m =
  addc s c (add s n m).
Proof.
  rewrite /add.
  elim: s c n m => [|s IH] /= c n m; first by case: c.
  case: (casen n) => [[bn n']|];
  case: (casen m) => [[bm m']|] //=.
  case: c => //.
  rewrite addc_cons addbA andTb. congr consn.
  rewrite addSn add0n ltnS addn_gt0 !lt0b IH (IH (1 < _)).
  case: bn bm => [] [] //=.
Qed.

Lemma add'E s : add s =2 add' s.
Proof.
  rewrite /add.
  elim: s => [|s IH] // n m /=.
  case En: (casen n) => [[bn n']|];
  case Em: (casen m) => [[bm m']|] //=.
    rewrite add_auxE -IH.
    by case: bn bm {En Em} => [] [].
  by case: m Em => [|[]].
Qed.

Lemma sizen_case n :
  sizen n = if casen n is Some (_, n') then (sizen n').+1
            else 0.
Proof. by case: n => [|[p|p|]]. Qed.

Lemma sizen_cons b n s :
  (sizen (consn b n) <= s.+1) = (sizen n <= s).
Proof. by case: n b => [|[p|p|]] []. Qed.

Lemma sizen_add s c n m :
  sizen n <= s ->
  sizen m <= s ->
  sizen (add_aux s c n m) <= s.
Proof.
  elim: s c n m => [|s IH] c n m //=.
  rewrite 2!sizen_case.
  case En: (casen n) => [[bn n']|];
  case Em: (casen m) => [[bm m']|] //=.
  - by rewrite sizen_cons; apply: IH.
  - move=> H _; apply: sizen_addc.
    by rewrite sizen_case En.
  - move=> _ H; apply: sizen_addc.
    by rewrite sizen_case Em.
  by case: c.
Qed.

Lemma add_auxC s c : commutative (add_aux s c).
Proof.
  elim: s c => [|s IH] c n m //=.
  case: (casen n) (casen m) => [[bn n']|] [[bm m']|] //=.
  by rewrite IH -!addbA (addbC bn) -!addnA (addnC bn).
Qed.

Structure word n := Word {
  bits :> N;
  _ : sizen bits <= n
}.

Lemma word_size n (w : word n) : sizen w <= n.
Proof. by case: w. Qed.

Canonical word_subType n := [subType for @bits n].

Definition word_eqMixin n := [eqMixin of word n by <:].
Canonical word_eqType n := Eval hnf in EqType (word n) (word_eqMixin n).

Definition addw n (w1 w2 : word n) : word n :=
  Word (sizen_add false (word_size w1) (word_size w2)).

Lemma addwC n : commutative (@addw n).
Proof.
  move=> w1 w2.
  apply: val_inj => /=.
  exact: add_auxC.
Qed.
