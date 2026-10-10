-- Authoring contract for enemy action sequences. Stage ordering/loop semantics
-- require native pose review before combat use; this is not an impact-time table.
return {
 xiaotaotie={move='fmove',skills={blow={'blow'},bomb={'bomb'},butt={'butt'},swing={'swing'},roll={'rollStart','rollEnd'}}},
 dataotie={move='fmove',skills={trample={'trample'},swing={'swing'},pounce={'pounce'},shot={'shot'},rush={'rush','rush1','rush2','rush3'}}},
 xiaoshanxiao={move='move',skills={throw={'throw'},evade={'evade'},litter={'litter'},rush={'rush'},scratch={'scratch'}}},
 dashanxiao={move='move',skills={throw={'throw'},slum={'slum'},punch={'punch'},ambush={'ambush1','ambush2'}}},
 xiaohuli={move='move',skills={charm={'charm'},charge={'charge'},pretend={'pretend'},cute={'cute'}}},
 dahuli={move='move',skills={slice={'slice','slice1'},parry={'parry','parry2','parry3','parry4'},hormone={'hormone','hormone2','hormone3'},blade={'blade','blade1','blade2'},ninja={'ninja','ninja2','ninja3','ninja4','ninja5','ninja6'}}},
 xiaohuayao={move='move',skills={blossom={'blossom'},leech={'leech'},pull={'pull'}}},
 dahuayao={move='move',skills={attack={'attack'},twine={'twine'},transv={'transv1','transv2','transv3'},seed={'seed1','seed2','seed3'}}},
 xiaoyingzhao={move='move',skills={jump={'jump','jump2','jump3','jump4'},kick={'kick'}}},
 zhongyingzhao={move='move',skills={rob={'rob','rob2','rob3','rob4'},shoot={'shoot'},punch={'punch'}}},
 dayingzhao={move='move',skills={punch={'punch'},hunt={'hunt'},massive={'massive'},wave={'wave'},hero={'hero','hero2','hero3'}}},
}
