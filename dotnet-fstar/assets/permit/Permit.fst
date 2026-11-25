module Permit

let claim (available:bool)
  : r:(bool & bool){ fst r == available /\ snd r == false }
  = (available, false)

let second_claim_fails (available:bool)
  : Lemma (fst (claim (snd (claim available))) == false)
  = ()
