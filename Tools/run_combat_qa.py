"""Run a known combat QA entry with a verified optimized runtime and isolated saves."""
import argparse
import hashlib
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

def runtime_error_lines(log_text):
    lines = log_text.splitlines()
    return [line for index, line in enumerate(lines)
            if '[runtime error]' in line or ('[error]' in line and any(
                following.lstrip().lower().startswith('stack traceback')
                for following in lines[index+1:index+4]))]


TESTS = {
    'ending-os-scroll': ('EndingOsScrollNative', 'ending-os-scroll-result.json'),
    'final-support-display': ('FinalSupportDisplayNative', 'final-support-display-result.json'),
    'learner-muzzle-calibration': ('LearnerMuzzleCalibrationNative', 'learner-muzzle-calibration-result.json'),
    'boss-flank-muzzle-geometry': ('BossFlankMuzzleGeometryNative', 'boss-flank-muzzle-geometry-result.json'),
    'boss-demonstration-cleanup': ('BossDemonstrationCleanupNative', 'boss-demonstration-cleanup-result.json'),
    'default-continue-entry': ('DefaultContinueEntryNative', 'default-continue-entry-result.json'),
    'default-opening-entry': ('DefaultOpeningEntryNative', 'default-opening-entry-result.json'),
    'pursuit-input-availability': ('PursuitInputAvailabilityNative', 'pursuit-input-availability-result.json'),
    'pursuit-medicine-settlement': ('PursuitMedicineSettlementNative', 'pursuit-medicine-settlement-result.json'),
    'production-return-soak': ('ProductionReturnSoakNative', 'production-return-soak-result.json'),
    'remaining-battle-input': ('RemainingBattleInputNative', 'remaining-battle-input-result.json'),
    'ground-input-availability': ('GroundInputAvailabilityNative', 'ground-input-availability-result.json'),
    'boss-victory-report-layout': ('BossVictoryReportLayoutNative', 'boss-victory-report-layout-result.json'),
    'boss-manual-head-reachability': ('BossManualHeadReachabilityNative', 'boss-manual-head-reachability-result.json'),
    'fresh-final-failure-retry-current': ('FreshFinalFailureRetryCurrentNative', 'fresh-final-failure-retry-current-result.json'),
    'recovery-hold-continuity': ('RecoveryHoldContinuityNative', 'recovery-hold-continuity-result.json'),
    'status-view-text-lifetime': ('StatusViewTextLifetimeNative', 'status-view-text-lifetime-result.json'),
    'actual-journey-report-bounds': ('ActualJourneyReportBoundsNative', 'actual-journey-report-bounds-result.json'),
    'actual-journey-loss-settlement': ('ActualJourneyLossSettlementNative', 'actual-journey-loss-settlement-result.json'),
    'support-shield-geometry-lifetime': ('SupportShieldGeometryLifetimeNative', 'support-shield-geometry-lifetime-result.json'),
    'patrol-release-outcome-native': ('PatrolReleaseOutcomeNative', 'patrol-release-outcome-result.json'),
    'unavailable-movement': ('UnavailableMovementNative', 'unavailable-movement-result.json'),
    'aim-hint-text-lifetime': ('AimHintTextLifetimeNative', 'aim-hint-text-lifetime-result.json'),
    'failure-reason': ('FailureReasonNative', 'failure-reason-result.json'),
    'actual-party-defeat-reason': ('ActualPartyDefeatReasonNative', 'actual-party-defeat-reason-result.json'),
    'os-boss-resource-loadout': ('OSBossResourceLoadoutNative', 'os-boss-resource-loadout-result.json'),
    'boss-resource-feedback': ('BossResourceFeedbackNative', 'boss-resource-feedback-result.json'),
    'supply-budget-advice-layout': ('SupplyBudgetAdviceLayoutNative', 'supply-budget-advice-layout-result.json'),
    'os-current-pursuit': ('OSCurrentPursuitNative', 'os-current-pursuit-result.json'),
    'pursuit-success-layout': ('PursuitSuccessLayoutNative', 'pursuit-success-layout-result.json'),
    'low-resource-factory-resume': ('LowResourceFactoryResumeNative', 'low-resource-factory-resume-result.json'),
    'ambush-warning-pursuit-retry': ('AmbushWarningPursuitRetryNative', 'ambush-warning-pursuit-retry-result.json'),
    'ambush-warning-ruins-route': ('AmbushWarningRuinsRouteNative', 'ambush-warning-ruins-route-result.json'),
    'ambush-warning-cancel': ('AmbushWarningCancelNative', 'ambush-warning-cancel-result.json'),
    'ambush-warning': ('AmbushWarningNative', 'ambush-warning-result.json'),
    'shan-claw-current': ('ShanClawCurrentNative', 'shan-claw-current-result.json'),
    'shan-hand-combat-current': ('ShanHandCombatCurrentNative', 'shan-hand-combat-current-result.json'),
    'big-shan-hand-current': ('BigShanHandCurrentNative', 'big-shan-hand-current-result.json'),
    'ambush-current': ('AmbushCurrentNative', 'ambush-current-result.json'),

    'shan-rush-current': ('ShanRushCurrentNative', 'shan-rush-current-result.json'),
    'big-shan-combo-current': ('BigShanComboCurrentNative', 'big-shan-combo-current-result.json'),
    'shan-tactics-current': ('ShanTacticsCurrentNative', 'shan-tactics-current-result.json'),
    'flower-skills-current': ('FlowerSkillsCurrentNative', 'flower-skills-current-result.json'),
    'big-taotie-skills-current': ('BigTaotieSkillsCurrentNative', 'big-taotie-skills-current-result.json'),
    'enemy-skill-cycle-current': ('EnemySkillCycleCurrentNative', 'enemy-skill-cycle-current-result.json'),
    'enemy-skills-current': ('EnemySkillsCurrentNative', 'enemy-skills-current-result.json'),
    'mentor-input-provenance': ('MentorInputProvenanceNative', 'mentor-input-provenance-result.json'),
    'native-name-input-current': ('NativeNameInputCurrent', 'native-name-input-current-result.json'),
    'font-atlas-live-labels': ('FontAtlasLiveLabelsNative', 'font-atlas-live-labels-result.json'),
    'font-atlas-lifetime': ('FontAtlasLifetimeNative', 'font-atlas-lifetime-result.json'),
    'ending-title-lifecycle': ('EndingTitleLifecycleNative', 'ending-title-lifecycle-result.json'),
    'input-box-buffer': ('InputBoxBufferNative', 'input-box-buffer-result.json'),
    'big-yingzhao-recovery-cadence': ('BigYingzhaoRecoveryCadenceNative', 'big-yingzhao-recovery-cadence-result.json'),
    'enemy-recovery-deadline': ('EnemyRecoveryDeadlineNative', 'enemy-recovery-deadline-result.json'),
    'fresh-defense-failure-retry-current': ('FreshDefenseFailureRetryCurrentNative', 'fresh-defense-failure-retry-current-result.json'),
    'recovery-stationary-policy': ('RecoveryStationaryPolicyNative', 'recovery-stationary-policy-result.json'),
    'yingzhao-public-wuyun-protection': ('YingzhaoPublicWuyunProtectionNative', 'yingzhao-public-wuyun-protection-result.json'),
    'yingzhao-coordination-observation': ('YingzhaoCoordinationObservationNative', 'yingzhao-coordination-observation-result.json'),
    'full-game-soak': ('FullGameSoakNative', 'full-game-soak-result.json'),
    'full-game-cache-probe': ('FullGameCacheProbeNative', 'full-game-cache-probe-result.json'),
    'full-game-reference-probe': ('FullGameReferenceProbeNative', 'full-game-reference-probe-result.json'),
    'ui-xml-loop-lifecycle': ('UiXmlLoopLifecycleNative', 'ui-xml-loop-lifecycle-result.json'),
    'native-window-resume-keyboard': ('NativeWindowResumeKeyboard', 'native-window-resume-keyboard-result.json'),
    'ui-loop-lifecycle': ('UiLoopLifecycleNative', 'ui-loop-lifecycle-result.json'),
    'story-animation-lifecycle': ('StoryAnimationLifecycleNative', 'story-animation-lifecycle-result.json'),
    'story-xml-animation-lifecycle': ('StoryXmlAnimationLifecycleNative', 'story-xml-animation-lifecycle-result.json'),
    'settlement-displacement': ('SettlementDisplacementNative', 'settlement-displacement-result.json'),
    'playing-gather-boundary': ('PlayingGatherBoundaryNative', 'playing-gather-boundary-result.json'),
    'recovery-threat-side-native': ('RecoveryThreatSideNative', 'recovery-threat-side-result.json'),
    'gather-order-trace-native': ('GatherOrderTraceNative', 'gather-order-trace-result.json'),
    'gather-trace-formal-save-native': ('GatherTraceFormalSaveNative', 'gather-trace-formal-save-result.json'),
    'gather-pending-skills': ('GatherPendingSkillsNative', 'gather-pending-skills-result.json'),
    'arena-interrupted-action-trace': ('ArenaInterruptedActionTraceNative', 'arena-interrupted-action-trace-result.json'),
    'part-action-interruption': ('PartActionInterruptionNative', 'part-action-interruption-result.json'),
    'optimization-performance': ('OptimizationPerformanceNative', 'optimization-performance-result.json'),
    'optimization-degradation': ('OptimizationDegradationNative', 'optimization-degradation-result.json'),
    'optimization-review-ui': ('OptimizationReviewUINative', 'optimization-review-ui-result.json'),
    'part-aim-native': ('PartAimNative', 'part-aim-native-result.json'),
    'yingzhao-head-coverage': ('YingzhaoHeadCoverageNative', 'yingzhao-head-coverage-result.json'),
    'low-resource-opening-hud-resume': ('LowResourceOpeningHUDResumeNative', 'low-resource-opening-hud-resume-result.json'),
    'low-resource-opening-hud': ('LowResourceOpeningHUDNative', 'low-resource-opening-hud-result.json'),
    'boss-opening-countdown': ('BossOpeningCountdownNative', 'boss-opening-countdown-result.json'),
    'boss-recovery-warning-boundary': ('BossRecoveryWarningBoundaryNative', 'boss-recovery-warning-boundary-result.json'),
    'critical-machine-warning': ('CriticalMachineWarningNative', 'critical-machine-warning-result.json'),
    'boss-demonstration-support-warning': ('BossDemonstrationSupportWarningNative', 'boss-demonstration-support-warning-result.json'),
    'machine-front-warning-boundary': ('MachineFrontWarningBoundaryNative', 'machine-front-warning-boundary-result.json'),

    'current-tactical-adoption-checkpoint': ('CurrentTacticalAdoptionCheckpointNative', 'current-tactical-adoption-checkpoint-result.json'),
    'fresh-big-yingzhao-tactical-deployment': ('FreshBigYingzhaoCurrentNative', 'fresh-big-yingzhao-tactical-deployment-result.json'),
    'fresh-big-yingzhao-wave-control': ('FreshBigYingzhaoCurrentNative', 'fresh-big-yingzhao-wave-control-result.json'),
    'gather-deadline-feedback': ('GatherDeadlineFeedbackNative', 'gather-deadline-feedback-result.json'),
    'gather-feedback-cache': ('GatherFeedbackCacheNative', 'gather-feedback-cache-result.json'),
    'fresh-big-yingzhao-formation-control': ('FreshBigYingzhaoCurrentNative', 'fresh-big-yingzhao-formation-control-result.json'),
    'yingzhao-front-range': ('YingzhaoFrontRangeNative', 'yingzhao-front-range-result.json'),
    'fresh-big-yingzhao-visible-protection': ('FreshBigYingzhaoCurrentNative', 'fresh-big-yingzhao-visible-protection-result.json'),
    'yingzhao-magic-cleanup': ('YingzhaoMagicCleanupNative', 'yingzhao-magic-cleanup-result.json'),
    'fresh-boss-support-warning': ('FreshBigYingzhaoCurrentNative', 'fresh-boss-support-warning-result.json'),
    'yingzhao-public-tactical-lesson-native': ('YingzhaoPublicTacticalLessonNative', 'yingzhao-public-tactical-lesson-result.json'),
    'yingzhao-recent-learning-native': ('YingzhaoRecentLearningNative', 'yingzhao-recent-learning-result.json'),
    'yingzhao-captured-evidence-native': ('YingzhaoCapturedEvidenceNative', 'yingzhao-captured-evidence-result.json'),
    'yingzhao-shield-q': ('YingzhaoShieldQNative', 'yingzhao-shield-q-result.json'),
    'yingzhao-legacy-q-entry': ('YingzhaoLegacyQEntryNative', 'yingzhao-legacy-q-entry-result.json'),
    'yingzhao-stale-recomparison': ('YingzhaoStaleRecomparisonNative', 'yingzhao-stale-recomparison-result.json'),
    'living-support-native': ('LivingSupportNative', 'living-support-native-result.json'),
    'physical-shield-native': ('PhysicalShieldNative', 'physical-shield-native-result.json'),
    'yingzhao-support-status-native': ('YingzhaoSupportStatusNative', 'yingzhao-support-status-result.json'),
    'yingzhao-adopted-boss-natural-native': ('YingzhaoAdoptedBossNaturalNative', 'yingzhao-adopted-boss-natural-result.json'),
    'yingzhao-team-cover-natural-native': ('YingzhaoTeamCoverNaturalNative', 'yingzhao-team-cover-natural-result.json'),
    'yingzhao-safe-distance-natural-native': ('YingzhaoSafeDistanceNaturalNative', 'yingzhao-safe-distance-natural-result.json'),
    'yingzhao-escort-budget-natural-native': ('YingzhaoEscortBudgetNaturalNative', 'yingzhao-escort-budget-natural-result.json'),
    'native-held-input-observation': ('NativeHeldInputObservation', 'native-held-input-observation-result.json'),
    'native-boss-input-observation': ('NativeBossInputObservation', 'native-boss-input-observation-result.json'),
    'native-boss-movement-observation': ('NativeBossMovementObservation', 'native-boss-movement-observation-result.json'),
    'native-window-resume-input': ('NativeWindowResumeInput', 'native-window-resume-input-result.json'),
    'hud-input-availability': ('HUDInputAvailability', 'hud-input-availability-result.json'),
    'patrol-input-availability': ('PatrolInputAvailabilityNative', 'patrol-input-availability-result.json'),
    'yingzhao-precision-team-cover-natural-native': ('YingzhaoPrecisionTeamCoverNaturalNative', 'yingzhao-precision-team-cover-natural-result.json'),
    'yingzhao-report-size-recovery-native': ('YingzhaoReportSizeRecoveryNative', 'yingzhao-report-size-recovery-result.json'),
    'yingzhao-report-size-diagnostic-native': ('YingzhaoReportSizeDiagnosticNative', 'yingzhao-report-size-diagnostic-result.json'),
    'fresh-fox-motion-visual-current': ('FreshFoxMotionVisualCurrentNative', 'fresh-fox-motion-visual-current-result.json'),
    'fox-current-cycle-visual': ('FoxCurrentCycleVisualNative', 'fox-current-cycle-visual-result.json'),
    'yingzhao-dual-deployment-native': ('YingzhaoDualDeploymentNative', 'yingzhao-dual-deployment-result.json'),
    'yingzhao-adoption-ui-native': ('YingzhaoAdoptionUINative', 'yingzhao-adoption-ui-result.json'),
    'yingzhao-deployment-native': ('YingzhaoDeploymentNative', 'yingzhao-deployment-result.json'),
    'yingzhao-adoption-native': ('YingzhaoAdoptionNative', 'yingzhao-adoption-result.json'),
    'yingzhao-adoption-cold-native': ('YingzhaoAdoptionColdNative', 'yingzhao-adoption-cold-result.json'),
    'fresh-ending-checkpoint': ('FreshEndingCheckpointNative', 'fresh-ending-checkpoint-result.json'),
    'failure-result-layout': ('FailureResultLayoutNative', 'failure-result-layout-result.json'),
    'fresh-materials-retry': ('FreshMaterialsRetryNative', 'fresh-materials-retry-result.json'),
    'fresh-opening-scripted-resume': ('FreshOpeningScriptedResumeNative', 'fresh-opening-scripted-resume-result.json'),
    'fresh-investigation-scripted': ('FreshInvestigationScriptedNative', 'fresh-investigation-result.json'),
    'fresh-tutorial-precision': ('FreshTutorialPrecisionNative', 'fresh-tutorial-precision-result.json'),
    'fresh-opening-scripted': ('FreshOpeningScriptedNative', 'fresh-opening-scripted-result.json'),
    'fresh-materials-aimed': ('FreshMaterialsAimedNative', 'fresh-materials-aimed-result.json'),
    'formation-native': ('FormationNative', 'formation-native-result.json'),
    'formation-battle-movement': ('FormationBattleMovementNative', 'formation-battle-movement-result.json'),
    'formation-formal-regroup': ('FormationFormalRegroupNative', 'formation-formal-regroup-result.json'),
    'formation-materials-route': ('FormationMaterialsRouteNative', 'formation-materials-route-result.json'),
    'fresh-big-yingzhao-lanes': ('FreshBigYingzhaoLanesNative', 'fresh-big-yingzhao-lanes-result.json'),
    'fresh-big-yingzhao-regroup': ('FreshBigYingzhaoRegroupNative', 'fresh-big-yingzhao-regroup-result.json'),
    'fresh-big-yingzhao-parts-view': ('FreshBigYingzhaoPartsViewNative', 'fresh-big-yingzhao-parts-view-result.json'),
    'fresh-big-yingzhao-aim-guard': ('FreshBigYingzhaoAimGuardNative', 'fresh-big-yingzhao-aim-guard-result.json'),
    'fresh-big-yingzhao-current': ('FreshBigYingzhaoCurrentNative', 'fresh-big-yingzhao-current-result.json'),
    'fresh-disarm-current': ('FreshDisarmCurrentNative', 'fresh-disarm-current-result.json'),
    'twins-full-reaction-candidate': ('TwinsFullReactionCandidateNative', 'twins-full-reaction-candidate-result.json'),
    'twin-reaction-controller-candidate': ('TwinReactionControllerCandidateNative', 'twin-reaction-controller-candidate-result.json'),
    'training-soak-footprint': ('TrainingSoakFootprintNative', 'training-soak-footprint-result.json'),
    'fresh-rescue-reaction-failure-current': ('FreshRescueReactionFailureCurrentNative', 'fresh-rescue-reaction-failure-current-result.json'),
    'fresh-rescue-reactions-current': ('FreshRescueReactionsCurrentNative', 'fresh-rescue-reactions-current-result.json'),
    'twins-reaction-candidate': ('TwinsReactionCandidateNative', 'twins-reaction-candidate-result.json'),
    'training-soak-current': ('TrainingSoakCurrentNative', 'training-soak-current-result.json'),
    'fresh-ending-resume-current': ('FreshEndingResumeCurrentNative', 'fresh-ending-resume-current-result.json'),
    'fresh-chapter-three-current': ('FreshChapterThreeCurrentNative', 'fresh-chapter-three-current-result.json'),
    'fresh-ending-current': ('FreshEndingCurrentNative', 'fresh-ending-current-result.json'),
    'fresh-fox-motion-current': ('FreshFoxMotionCurrentNative', 'fresh-fox-motion-current-result.json'),
    'fresh-factory-current': ('FreshFactoryCurrentNative', 'fresh-factory-current-result.json'),
    'fresh-valley-days-current': ('FreshValleyDaysCurrentNative', 'fresh-valley-days-current-result.json'),
    'fresh-fox-trail-current': ('FreshFoxTrailCurrentNative', 'fresh-fox-trail-current-result.json'),
    'fresh-command-current': ('FreshCommandCurrentNative', 'fresh-command-current-result.json'),
    'fresh-valley-activities-current': ('FreshValleyActivitiesCurrentNative', 'fresh-valley-activities-current-result.json'),
    'fresh-valley-current': ('FreshValleyCurrentNative', 'fresh-valley-current-result.json'),
    'pursuit-earned-retry': ('PursuitEarnedRetryNative', 'pursuit-earned-retry-result.json'),
    'pursuit-earned-diagnostic': ('PursuitEarnedDiagnosticNative', 'pursuit-earned-diagnostic-result.json'),
    'fresh-ruins-current': ('FreshRuinsCurrentNative', 'fresh-ruins-current-result.json'),
    'fresh-recovery-current': ('FreshRecoveryCurrentNative', 'fresh-recovery-current-result.json'),
    'fresh-materials-current': ('FreshMaterialsCurrentNative', 'fresh-materials-current-result.json'),
    'fresh-medical-current': ('FreshMedicalCurrentNative', 'fresh-medical-current-result.json'),
    'fresh-aftertrial-current': ('FreshAfterTrialCurrentNative', 'fresh-aftertrial-current-result.json'),
    'fresh-liyena-current': ('FreshLiyenaCurrentNative', 'fresh-liyena-current-result.json'),
    'fresh-ayan-current': ('FreshAyanCurrentNative', 'fresh-ayan-current-result.json'),
    'fresh-energy-efficiency': ('FreshEnergyEfficiencyNative', 'fresh-energy-efficiency-result.json'),
    'training-text-cache': ('TrainingTextCacheNative', 'training-text-cache-result.json'),
    'training-categories': ('TrainingCategoriesNative', 'training-categories-result.json'),
    'fresh-energy-current': ('FreshEnergyCurrentNative', 'fresh-energy-current-result.json'),
    'fresh-wuyun-current': ('FreshWuyunCurrentNative', 'fresh-wuyun-current-result.json'),
    'fresh-cooperation-current': ('FreshCooperationCurrentNative', 'fresh-cooperation-current-result.json'),
    'fresh-ground-current': ('FreshGroundCurrentNative', 'fresh-ground-current-result.json'),
    'ground-rescue-notification-trace': ('GroundRescueNotificationTraceNative', 'ground-rescue-notification-trace-result.json'),
    'fresh-train-current': ('FreshTrainCurrentNative', 'fresh-train-current-result.json'),
    'fresh-opening-academy-resume': ('FreshOpeningAcademyResumeNative', 'fresh-opening-academy-resume-result.json'),
    'fresh-investigation': ('FreshInvestigationNative', 'fresh-investigation-result.json'),
    'fresh-opening-academy': ('FreshOpeningAcademyNative', 'fresh-opening-academy-result.json'),
    'rescue-health-feedback': ('RescueHealthFeedbackNative', 'rescue-health-feedback-result.json'),
    'chapter-three-ending-resume': ('ChapterThreeEndingResumeNative', 'chapter-three-ending-resume-result.json'),
    'chapter-three-ending': ('ChapterThreeEndingNative', 'chapter-three-ending-result.json'),
    'chapter-three-journey': ('ChapterThreeJourneyNative', 'chapter-three-journey-result.json'),
    'factory-journey-resume': ('FactoryJourneyResumeNative', 'factory-journey-resume-result.json'),
    'factory-journey': ('FactoryJourneyNative', 'factory-journey-result.json'),
    'roof-supply': ('RoofSupplyNative', 'roof-supply-result.json'),
    'roof-supply-failure': ('RoofSupplyFailureNative', 'roof-supply-failure-result.json'),
    'roof-report-durability': ('RoofReportDurabilityNative', 'roof-report-durability-result.json'),
    'researcher-supply-withdraw': ('ResearcherSupplyWithdrawNative', 'researcher-supply-withdraw-result.json'),
    'second-patrol-supply-withdraw': ('SecondPatrolSupplyWithdrawNative', 'second-patrol-supply-withdraw-result.json'),
    'researcher-supply': ('ResearcherSupplyNative', 'researcher-supply-result.json'),
    'second-patrol-supply': ('SecondPatrolSupplyNative', 'second-patrol-supply-result.json'),
    'infiltration-supply-withdraw': ('InfiltrationSupplyWithdrawNative', 'infiltration-supply-withdraw-result.json'),
    'infiltration-supply': ('InfiltrationSupplyNative', 'infiltration-supply-result.json'),
    'yingzhao-observation-full': ('YingzhaoObservationFullNative', 'yingzhao-observation-full-result.json'),
    'yingzhao-conserve-lesson': ('YingzhaoConserveLessonNative', 'yingzhao-conserve-lesson-result.json'),
    'yingzhao-blocked-part-review': ('YingzhaoBlockedPartReviewNative', 'yingzhao-blocked-part-review-result.json'),
    'yingzhao-actor-sources': ('YingzhaoActorSourcesNative', 'yingzhao-actor-sources-result.json'),
    'yingzhao-ui-load': ('YingzhaoUILoadNative', 'yingzhao-ui-load-result.json'),
    'yingzhao-observation-load': ('YingzhaoObservationLoadNative', 'yingzhao-observation-load-result.json'),
    'yingzhao-reachability': ('YingzhaoReachabilityNative', 'yingzhao-reachability-result.json'),
    'yingzhao-hit-lesson': ('YingzhaoHitLessonNative', 'yingzhao-hit-lesson-result.json'),
    'yingzhao-hunt-lesson': ('YingzhaoHuntLessonNative', 'yingzhao-hunt-lesson-result.json'),
    'yingzhao-validated-builder': ('YingzhaoValidatedBuilderNative', 'yingzhao-validated-builder-result.json'),
    'yingzhao-depth-diagnostic': ('YingzhaoDepthDiagnosticNative', 'yingzhao-depth-diagnostic-result.json'),
    'yingzhao-q-hazard-boundaries-native': ('YingzhaoQHazardBoundariesNative', 'yingzhao-q-hazard-boundaries-result.json'),
    'yingzhao-melee-body-reach-native': ('YingzhaoMeleeBodyReachNative', 'yingzhao-melee-body-reach-result.json'),
    'yingzhao-summon-melee': ('YingzhaoSummonMeleeNative', 'yingzhao-summon-melee-result.json'),
    'yingzhao-held-input': ('YingzhaoHeldInputNative', 'yingzhao-held-input-result.json'),
    'yingzhao-edge-frozen': ('YingzhaoEdgeFrozenNative', 'yingzhao-edge-frozen-result.json'),
    'yingzhao-edge-lesson': ('YingzhaoEdgeLessonNative', 'yingzhao-edge-lesson-result.json'),
    'yingzhao-arena-ui': ('YingzhaoArenaUINative', 'yingzhao-arena-ui-result.json'),
    'yingzhao-arena': ('YingzhaoArenaNative', 'yingzhao-arena-result.json'),
    'yingzhao-mentor-wave': ('YingzhaoMentorWaveNative', 'yingzhao-mentor-wave-result.json'),
    'yingzhao-assist-priority': ('YingzhaoAssistPriorityNative', 'yingzhao-assist-priority-result.json'),
    'yingzhao-branch-builder': ('YingzhaoBranchBuilderNative', 'yingzhao-branch-builder-result.json'),
    'yingzhao-builder': ('YingzhaoBuilderNative', 'yingzhao-builder-result.json'),
    'yingzhao-gain-probe': ('YingzhaoGainProbeNative', 'yingzhao-gain-probe-result.json'),
    'yingzhao-wuyun-alternating': ('YingzhaoWuyunAlternatingNative', 'yingzhao-wuyun-alternating-result.json'),
    'yingzhao-punch-lesson': ('YingzhaoPunchLessonNative', 'yingzhao-punch-lesson-result.json'),
    'yingzhao-alternating': ('YingzhaoAlternatingNative', 'yingzhao-alternating-result.json'),
    'yingzhao-wave-learning': ('YingzhaoWaveLearningNative', 'yingzhao-wave-learning-result.json'),
    'yingzhao-dual-threat': ('YingzhaoDualThreatNative', 'yingzhao-dual-threat-result.json'),
    'yingzhao-mixed-natural': ('YingzhaoMixedNaturalNative', 'yingzhao-mixed-natural-result.json'),
    'yingzhao-dodge-learning': ('YingzhaoDodgeLearningNative', 'yingzhao-dodge-learning-result.json'),
    'yingzhao-manual-movement': ('YingzhaoManualMovementNative', 'yingzhao-manual-movement-result.json'),
    'yingzhao-dodge': ('YingzhaoDodgeNative', 'yingzhao-dodge-result.json'),
    'yingzhao-wuyun-training': ('YingzhaoWuyunTrainingNative', 'yingzhao-wuyun-training-result.json'),
    'yingzhao-mentor-aim': ('YingzhaoMentorAimNative', 'yingzhao-mentor-aim-result.json'),
    'yingzhao-manual-head': ('YingzhaoManualHeadNative', 'yingzhao-manual-head-result.json'),
    'yingzhao-q-magic': ('YingzhaoQMagicNative', 'yingzhao-q-magic-result.json'),
    'yingzhao-trial-motion': ('YingzhaoTrialMotionNative', 'yingzhao-trial-motion-result.json'),
    'yingzhao-ranged': ('YingzhaoRangedNative', 'yingzhao-ranged-result.json'),
    'yingzhao-q-natural': ('YingzhaoQNaturalNative', 'yingzhao-q-natural-result.json'),
    'yingzhao-q-comparison-review': ('YingzhaoQComparisonReviewNative', 'yingzhao-q-comparison-review-result.json'),
    'yingzhao-q-comparison': ('YingzhaoQComparisonNative', 'yingzhao-q-comparison-result.json'),
    'yingzhao-q-entry': ('YingzhaoQEntryNative', 'yingzhao-q-entry-result.json'),
    'yingzhao-q-damage': ('YingzhaoQDamageNative', 'yingzhao-q-damage-result.json'),
    'yingzhao-q-cold': ('YingzhaoQColdNative', 'yingzhao-q-cold-result.json'),
    'yingzhao-candidate-cold': ('YingzhaoCandidateColdNative', 'yingzhao-candidate-cold-result.json'),
    'yingzhao-candidate-store': ('YingzhaoCandidateStoreNative', 'yingzhao-candidate-store-result.json'),
    'yingzhao-comparison': ('YingzhaoComparisonNative', 'yingzhao-comparison-result.json'),
    'yingzhao-entry': ('YingzhaoEntryNative', 'yingzhao-entry-result.json'),
    'yingzhao-mission-gate': ('YingzhaoMissionGateNative', 'yingzhao-mission-gate-result.json'),
    'yingzhao-history': ('YingzhaoHistoryNative', 'yingzhao-history-result.json'),
    'yingzhao-vitals': ('YingzhaoVitalsNative', 'yingzhao-vitals-result.json'),
    'yingzhao-q': ('YingzhaoQNative', 'yingzhao-q-result.json'),
    'yingzhao-policy': ('YingzhaoPolicyNative', 'yingzhao-policy-result.json'),
    'yingzhao-store-cold': ('YingzhaoStoreColdNative', 'yingzhao-store-cold-result.json'),
    'big-yingzhao-practice': ('BigYingzhaoPracticeNative', 'big-yingzhao-practice-result.json'),
    'yingzhao-aim': ('YingzhaoAimNative', 'yingzhao-aim-result.json'),
    'yingzhao-muzzle-matrix': ('YingzhaoMuzzleMatrixNative', 'yingzhao-muzzle-matrix-result.json'),
    'yingzhao-rule-migration': ('YingzhaoRuleMigrationNative', 'yingzhao-rule-migration-result.json'),
    'yingzhao-wave-reach': ('YingzhaoWaveReachNative', 'yingzhao-wave-reach-result.json'),
    'yingzhao-features': ('YingzhaoFeaturesNative', 'yingzhao-features-result.json'),
    'big-yingzhao-full': ('BigYingzhaoFullNative', 'big-yingzhao-full-result.json'),
    'big-yingzhao-settlement': ('BigYingzhaoSettlementNative', 'big-yingzhao-settlement-result.json'),
    'big-yingzhao-magic': ('BigYingzhaoMagicNative', 'big-yingzhao-magic-result.json'),
    'big-yingzhao-emission': ('BigYingzhaoEmissionNative', 'big-yingzhao-emission-result.json'),
    'big-yingzhao-projectiles': ('BigYingzhaoProjectilesNative', 'big-yingzhao-projectiles-result.json'),
    'big-yingzhao-armor': ('BigYingzhaoArmorNative', 'big-yingzhao-armor-result.json'),
    'disarm-low-gun-regression': ('DisarmLowGunRegressionNative', 'disarm-low-gun-regression-result.json'),
    'disarm-low-gun': ('DisarmLowGunTeachingNative', 'disarm-low-gun-result.json'),
    'disarm-weapon-regression': ('DisarmWeaponRegressionNative', 'disarm-weapon-regression-result.json'),
    'disarm-weapon-lessons': ('DisarmWeaponLessonsNative', 'disarm-weapon-lessons-result.json'),
    'disarm-cross-coaching': ('DisarmCrossCoachingNative', 'disarm-cross-coaching-result.json'),
    'disarm-weapon-boundary': ('DisarmWeaponBoundaryNative', 'disarm-weapon-boundary-result.json'),
    'disarm-cross-weapon-compare': ('DisarmCrossWeaponCompareNative', 'disarm-cross-weapon-compare-result.json'),
    'disarm-cross-weapon': ('DisarmCrossWeaponTeachingNative', 'disarm-cross-weapon-result.json'),
    'disarm-budget-matrix': ('DisarmBudgetMatrixNative', 'disarm-budget-matrix-result.json'),
    'disarm-melee-compare': ('DisarmMeleeCompareNative', 'disarm-melee-compare-result.json'),
    'disarm-range-version': ('DisarmRangeVersionNative', 'disarm-range-version-result.json'),
    'disarm-melee-teaching': ('DisarmMeleeTeachingNative', 'disarm-melee-teaching-result.json'),
    'disarm-cost-breakdown': ('DisarmCostBreakdownNative', 'disarm-cost-breakdown-result.json'),
    'disarm-attack-compare': ('DisarmAttackCompareNative', 'disarm-attack-compare-result.json'),
    'disarm-attack-teaching': ('DisarmAttackTeachingNative', 'disarm-attack-teaching-result.json'),
    'disarm-coverage-compare': ('DisarmCoverageCompareNative', 'disarm-coverage-compare-result.json'),
    'disarm-coverage': ('DisarmCoverageNative', 'disarm-coverage-result.json'),
    'disarm-coaching': ('DisarmCoachingNative', 'disarm-coaching-result.json'),
    'disarm-comparison-save': ('DisarmComparisonSaveNative', 'disarm-comparison-save-result.json'),
    'disarm-comparison-history': ('DisarmComparisonHistoryNative', 'disarm-comparison-history-result.json'),
    'disarm-comparison-store': ('DisarmComparisonStoreNative', 'disarm-comparison-store-result.json'),
    'disarm-wuyun-comparison': ('DisarmWuyunComparisonNative', 'disarm-wuyun-comparison-result.json'),
    'disarm-comparison-ui': ('DisarmComparisonUINative', 'disarm-comparison-ui-result.json'),
    'disarm-compare': ('DisarmCompareNative', 'disarm-compare-result.json'),
    'disarm-candidate-trial': ('DisarmCandidateTrialNative', 'disarm-candidate-trial-result.json'),
    'disarm-policy-store': ('DisarmPolicyStoreNative', 'disarm-policy-store-result.json'),
    'disarm-save-lifecycle': ('DisarmSaveLifecycleNative', 'disarm-save-lifecycle-result.json'),
    'disarm-demonstration': ('DisarmDemonstrationNative', 'disarm-demonstration-result.json'),
    'disarm-credit': ('DisarmCreditNative', 'disarm-credit-result.json'),
    'disarm-execution': ('DisarmExecutionNative', 'disarm-execution-result.json'),
    'disarm-review-ui': ('DisarmReviewNative', 'disarm-review-ui-result.json'),
    'disarm-store-cold': ('DisarmStoreColdRead', 'disarm-store-cold-result.json'),
    'disarm-store': ('DisarmStoreNative', 'disarm-store-result.json'),
    'disarm-resource-review': ('DisarmResourceReviewNative', 'disarm-resource-review-result.json'),
    'disarm-empty-resource': ('DisarmEmptyResourceNative', 'disarm-empty-resource-result.json'),
    'disarm-resource': ('DisarmResourceNative', 'disarm-resource-result.json'),
    'tutorial-held-movement': ('TutorialHeldMovement', 'tutorial-held-movement-result.json'),
    'tutorial-movement-diagnostic': ('TutorialMovementDiagnostic', 'tutorial-movement-diagnostic-result.json'),
    'tutorial-native-diagnostic': ('TutorialNativeDiagnostic', 'tutorial-native-diagnostic-result.json'),
    'tutorial-diagnostic': ('TutorialDiagnostic', 'tutorial-diagnostic-result.json'),
    'pursuit-consumable-fault': ('PursuitConsumableFaultNative', 'pursuit-consumable-fault-result.json'),
    'pursuit-supply-victory': ('PursuitSupplyVictoryNative', 'pursuit-supply-victory-result.json'),
    'pursuit-supply': ('PursuitSupplyNative', 'pursuit-supply-result.json'),
    'ground-supply-entry': ('GroundSupplyEntryNative', 'ground-supply-entry-result.json'),
    'energy-budget-comparison': ('EnergyBudgetComparisonNative', 'energy-budget-comparison-result.json'),
    'energy-budget-advice': ('EnergyBudgetAdviceNative', 'energy-budget-advice-result.json'),
    'energy-supply-tactics': ('EnergySupplyTacticsNative', 'energy-supply-tactics-result.json'),
    'ground-supply-natural': ('GroundSupplyNaturalNative', 'ground-supply-natural-result.json'),
    'ground-supply': ('GroundSupplyNative', 'ground-supply-result.json'),
    'mission-supply-briefing': ('MissionSupplyBriefingNative', 'mission-supply-briefing-result.json'),
    'mission-supply': ('MissionSupplyNative', 'mission-supply-result.json'),
    'resource-restraint-review': ('ResourceRestraintReviewNative', 'resource-restraint-review-result.json'),
    'resource-budget-review': ('ResourceBudgetReviewNative', 'resource-budget-review-result.json'),
    'resource-scenario-review': ('ResourceScenarioReviewNative', 'resource-scenario-review-result.json'),
    'resource-scenario-trials': ('ResourceScenarioTrialsNative', 'resource-scenario-trials-result.json'),
    'resource-restraint-matrix': ('ResourceRestraintMatrixNative', 'resource-restraint-matrix-result.json'),
    'resource-restraint-trials': ('ResourceRestraintTrialsNative', 'resource-restraint-trials-result.json'),
    'resource-restraint-demo': ('ResourceRestraintDemoNative', 'resource-restraint-demo-result.json'),
    'resource-manual-aim': ('ResourceManualAimNative', 'resource-manual-aim-result.json'),
    'resource-attack-demo': ('ResourceAttackDemoNative', 'resource-attack-demo-result.json'),
    'resource-c45-review': ('ResourceC45ReviewNative', 'resource-c45-review-result.json'),
    'resource-c45-trials': ('ResourceC45TrialsNative', 'resource-c45-trials-result.json'),
    'resource-c45-player': ('ResourceC45PlayerNative', 'resource-c45-player-result.json'),
    'resource-demo-player': ('ResourceDemoPlayerNative', 'resource-demo-player-result.json'),
    'resource-policy': ('ResourcePolicyNative', 'resource-policy-result.json'),
    'flower-spatial-policy': ('FlowerSpatialPolicy', 'flower-spatial-policy-result.json'),
    'resource-exploration-panel': ('ResourceExplorationPanelNative', 'resource-exploration-panel-result.json'),
    'resource-exploration': ('ResourceExplorationNative', 'resource-exploration-result.json'),
    'resource-supplied-review': ('ResourceSuppliedReviewNative', 'resource-supplied-review-result.json'),
    'resource-review-panel': ('ResourceReviewPanelNative', 'resource-review-panel-result.json'),
    'resource-trials-reload': ('ResourceTrialsReload', 'resource-trials-reload-result.json'),
    'resource-trial-panel': ('ResourceTrialPanelNative', 'resource-trial-panel-result.json'),
    'q-telemetry-reload': ('FlowerQTelemetryReload', 'flower-q-telemetry-reload-result.json'),
    'resource-q-supplied-trials': ('ResourceQSuppliedTrials', 'resource-q-supplied-trials-result.json'),
    'resource-q-action-audit': ('ResourceQActionAudit', 'resource-q-action-audit-result.json'),
    'resource-q-targeted': ('ResourceQTargetedPractice', 'resource-q-targeted-practice-result.json'),
    'resource-q-targeted-audit': ('ResourceQTargetedAudit', 'resource-q-targeted-audit-result.json'),
    'resource-continuous-decision': ('ResourceContinuousDecisionNative', 'resource-continuous-decision-result.json'),
    'resource-continuous-review': ('ResourceContinuousReviewNative', 'resource-continuous-review-result.json'),
    'resource-q-generalization': ('ResourceQGeneralizationNative', 'resource-q-generalization-result.json'),
    'resource-generalization-review': ('ResourceGeneralizationReviewNative', 'resource-generalization-review-result.json'),
    'resource-q-multi-practice': ('ResourceQMultiPracticeNative', 'resource-q-multi-practice-result.json'),
    'resource-coverage-panel': ('ResourceCoveragePanelNative', 'resource-coverage-panel-result.json'),
    'resource-q-four-source': ('ResourceQFourSourceEvaluation', 'resource-q-four-source-evaluation-result.json'),
    'resource-four-source-review': ('ResourceFourSourceReviewNative', 'resource-four-source-review-result.json'),
    'resource-q-full-coverage': ('ResourceQFullCoverage', 'resource-q-full-coverage-result.json'),
    'resource-full-coverage-review': ('ResourceFullCoverageReviewNative', 'resource-full-coverage-review-result.json'),
    'resource-fallback': ('ResourceFallbackNative', 'resource-fallback-result.json'),
    'resource-fallback-review': ('ResourceFallbackReviewNative', 'resource-fallback-review-result.json'),
    'resource-small-target-fallback': ('ResourceSmallTargetFallbackNative', 'resource-small-target-fallback-result.json'),
    'resource-small-target-review': ('ResourceSmallTargetReviewNative', 'resource-small-target-review-result.json'),
    'resource-assessment': ('ResourceAssessmentNative', 'resource-assessment-result.json'),
    'resource-q-trials': ('ResourceQFrozenTrials', 'resource-q-frozen-trials-result.json'),
    'resource-q-panel': ('ResourceQPanelNative', 'resource-q-panel-result.json'),
    'resource-q-cumulative': ('ResourceQCumulative', 'resource-q-cumulative-result.json'),
    'resource-practice-store': ('ResourcePracticeStoreNative', 'resource-practice-store-result.json'),
    'resource-practice-ui': ('ResourcePracticeUI', 'resource-practice-ui-result.json'),
    'resource-virtual-source': ('VirtualResourceSource', 'virtual-resource-source-result.json'),
    'resource-virtual': ('VirtualResourceTraining', 'virtual-resource-training-result.json'),
    'resource-default': ('ResourceDefaultVictory', 'resource-default-victory-result.json'),
    'resource-baseline': ('ResourceBudgetBaseline', 'resource-budget-baseline-result.json'),
    'resource-candidate': ('ResourceBudgetCandidate', 'resource-budget-candidate-result.json'),
    'resource-q': ('ResourceQLearningNative', 'resource-q-learning-result.json'),
    'economy-online': ('EconomyOnlineResourceTrace', 'economy-online-resource-trace-result.json'),
    'economy-public': ('EconomyPublicPreparation', 'economy-public-preparation-result.json'),
    'supply-recovery': ('SupplyRecoveryNative', 'supply-recovery-native-result.json'),
    'economy-combat': ('EconomyCombatPerformance', 'economy-combat-performance-result.json'),
    'economy-pressure': ('EconomyWritePressure', 'economy-write-pressure-result.json'),
    'economy-factory': ('EconomyFactoryFlow', 'economy-factory-flow-result.json'),
    'defense-supply-entry': ('DefenseSupplyEntryNative', 'defense-supply-entry-result.json'),
    'rescue-supply-entry': ('RescueSupplyEntryNative', 'rescue-supply-entry-result.json'),
    'final-supply-entry': ('FinalSupplyEntryNative', 'final-supply-entry-result.json'),
    'rescue-supply': ('RescueSupplyNative', 'rescue-supply-result.json'),
    'final-supply': ('FinalSupplyNative', 'final-supply-result.json'),
    'defense-supply': ('DefenseSupplyNative', 'defense-supply-result.json'),
    'optional-formal-cold-read': ('OptionalFormalColdRead', 'optional-formal-cold-read-result.json'),
    'loadout-advice': ('LoadoutAdviceNative', 'loadout-advice-result.json'),
    'optional-formal-mission': ('OptionalFormalMissionNative', 'optional-formal-mission-result.json'),
    'optional-weapon-battle': ('OptionalWeaponBattleNative', 'optional-weapon-battle-result.json'),
    'optional-weapon-loadout': ('OptionalWeaponLoadoutNative', 'optional-weapon-loadout-result.json'),
    'supply-loadout': ('SupplyLoadoutNative', 'supply-loadout-native-result.json'),
    'economy-learner': ('EconomyLearnerFire', 'economy-learner-fire-result.json'),
    'economy-stolen': ('EconomyStolenFire', 'economy-stolen-fire-result.json'),
    'economy-fire': ('EconomyMentorFire', 'economy-mentor-fire-result.json'),
    'mission-economy': ('MissionEconomyNative', 'mission-economy-native-result.json'),
    'economy-store': ('EconomyStoreNative', 'economy-store-native-result.json'),
    'result-navigation': ('FactoryResultNavigation', 'factory-result-navigation-result.json'),
    'flower-outcome': ('FlowerOutcomeNative', 'flower-outcome-result.json'),
    'big-yingzhao-hero': ('BigYingzhaoHeroNative', 'big-yingzhao-hero-result.json'),
    'big-yingzhao-hunt': ('BigYingzhaoHuntNative', 'big-yingzhao-hunt-result.json'),
    'summon-report-provenance': ('SummonReportProvenanceNative', 'summon-report-provenance-result.json'),
    'big-yingzhao-wave-cadence': ('BigYingzhaoWaveCadenceNative', 'big-yingzhao-wave-cadence-result.json'),
    'big-yingzhao-wave': ('BigYingzhaoWaveNative', 'big-yingzhao-wave-result.json'),
    'big-yingzhao-combat': ('BigYingzhaoCombatNative', 'big-yingzhao-combat-result.json'),
    'big-yingzhao-pose': ('BigYingzhaoPoseNative', 'big-yingzhao-pose-result.json'),
    'yingzhao-wind-counter-limits': ('YingzhaoWindCounterLimitsNative', 'yingzhao-wind-counter-limits-result.json'),
    'yingzhao-skill-policy-cold': ('YingzhaoSkillPolicyColdNative', 'yingzhao-skill-policy-cold-result.json'),
    'yingzhao-q-skills-cold': ('YingzhaoQSkillsColdNative', 'yingzhao-q-skills-cold-result.json'),
    'yingzhao-q-cancel-cold': ('YingzhaoQCancelColdNative', 'yingzhao-q-cancel-cold-result.json'),
    'yingzhao-wind-review': ('YingzhaoWindReviewNative', 'yingzhao-wind-review-result.json'),
    'yingzhao-wind-context-lesson': ('YingzhaoWindContextLessonNative', 'yingzhao-wind-context-lesson-result.json'),
    'yingzhao-fresh-corpus': ('YingzhaoFreshCorpusNative', 'yingzhao-fresh-corpus-result.json'),
    'yingzhao-exposed-natural': ('YingzhaoExposedNaturalNative', 'yingzhao-exposed-natural-result.json'),
    'yingzhao-return-natural': ('YingzhaoReturnNaturalNative', 'yingzhao-return-natural-result.json'),
    'yingzhao-range-natural': ('YingzhaoRangeNaturalNative', 'yingzhao-range-natural-result.json'),
    'yingzhao-mentor-clearance-trace': ('YingzhaoMentorClearanceTraceNative', 'yingzhao-mentor-clearance-trace-result.json'),
    'yingzhao-mixed-window': ('YingzhaoMixedWindowNative', 'yingzhao-mixed-window-result.json'),
    'yingzhao-dodge-window': ('YingzhaoDodgeWindowNative', 'yingzhao-dodge-window-result.json'),
    'yingzhao-clearance': ('YingzhaoClearanceNative', 'yingzhao-clearance-result.json'),
    'empty-loadout-advice': ('EmptyLoadoutAdviceNative', 'empty-loadout-advice-result.json'),
    'yingzhao-loadout-advice': ('YingzhaoLoadoutAdviceNative', 'yingzhao-loadout-advice-result.json'),
    'yingzhao-public-post-armor-compare': ('YingzhaoPublicPostArmorCompareNative', 'yingzhao-public-post-armor-compare-result.json'),
    'chapter-medicine-input': ('ChapterMedicineInputNative', 'chapter-medicine-input-result.json'),
    'yingzhao-public-post-armor': ('YingzhaoPublicPostArmorNative', 'yingzhao-public-post-armor-result.json'),
    'yingzhao-public-threat-lesson': ('YingzhaoPublicThreatLessonNative', 'yingzhao-public-threat-lesson-result.json'),
    'yingzhao-public-threat-compare': ('YingzhaoPublicThreatCompareNative', 'yingzhao-public-threat-compare-result.json'),
    'yingzhao-emp-formal-report': ('YingzhaoEMPFormalReportNative', 'yingzhao-emp-formal-report-result.json'),
    'yingzhao-emp-feedback': ('YingzhaoEMPFeedbackNative', 'yingzhao-emp-feedback-result.json'),
    'yingzhao-contribution-review': ('YingzhaoContributionReviewNative', 'yingzhao-contribution-review-result.json'),
    'yingzhao-survival-review': ('YingzhaoSurvivalReviewNative', 'yingzhao-survival-review-result.json'),
    'yingzhao-close-shot': ('YingzhaoCloseShotNative', 'yingzhao-close-shot-result.json'),
    'yingzhao-close-aim': ('YingzhaoCloseAimNative', 'yingzhao-close-aim-result.json'),
    'yingzhao-mentor-boundary': ('YingzhaoMentorBoundaryNative', 'yingzhao-mentor-boundary-result.json'),
    'yingzhao-mentor-trace': ('YingzhaoMentorTraceNative', 'yingzhao-mentor-trace-result.json'),
    'yingzhao-independent-natural': ('YingzhaoIndependentNaturalNative', 'yingzhao-independent-natural-result.json'),
    'yingzhao-coverage-audit': ('YingzhaoCoverageAuditNative', 'yingzhao-coverage-audit-result.json'),
    'yingzhao-range-lesson': ('YingzhaoRangeLessonNative', 'yingzhao-range-lesson-result.json'),
    'yingzhao-return-lesson': ('YingzhaoReturnLessonNative', 'yingzhao-return-lesson-result.json'),
    'yingzhao-exposed-lesson': ('YingzhaoExposedLessonNative', 'yingzhao-exposed-lesson-result.json'),
    'yingzhao-fresh-natural': ('YingzhaoFreshNaturalNative', 'yingzhao-fresh-natural-result.json'),
    'yingzhao-wind-natural': ('YingzhaoWindNaturalNative', 'yingzhao-wind-natural-result.json'),
    'yingzhao-q-skill-cancel': ('YingzhaoQSkillCancelNative', 'yingzhao-q-skill-cancel-result.json'),
    'yingzhao-q-skills': ('YingzhaoQSkillsNative', 'yingzhao-q-skills-result.json'),
    'yingzhao-skill-policy': ('YingzhaoSkillPolicyNative', 'yingzhao-skill-policy-result.json'),
    'yingzhao-skill-features': ('YingzhaoSkillFeaturesNative', 'yingzhao-skill-features-result.json'),
    'yingzhao-skill-evidence': ('YingzhaoSkillEvidenceNative', 'yingzhao-skill-evidence-result.json'),
    'yingzhao-magic-lifecycle': ('YingzhaoMagicLifecycleNative', 'yingzhao-magic-lifecycle-result.json'),
    'yingzhao-boundary-cooldown': ('YingzhaoBoundaryCooldownNative', 'yingzhao-boundary-cooldown-result.json'),
    'yingzhao-edge-varied-natural': ('YingzhaoEdgeVariedNaturalNative', 'yingzhao-edge-varied-natural-result.json'),
    'yingzhao-counter-timing': ('YingzhaoCounterTimingNative', 'yingzhao-counter-timing-result.json'),
    'yingzhao-melee-spacing': ('YingzhaoMeleeSpacingNative', 'yingzhao-melee-spacing-result.json'),
    'yingzhao-spacing-model': ('YingzhaoSpacingModelNative', 'yingzhao-spacing-model-result.json'),
    'yingzhao-empty-ammo-lesson': ('YingzhaoEmptyAmmoLessonNative', 'yingzhao-empty-ammo-lesson-result.json'),
    'yingzhao-empty-ammo-model': ('YingzhaoEmptyAmmoModelNative', 'yingzhao-empty-ammo-model-result.json'),
    'yingzhao-leaf-alternatives': ('YingzhaoLeafAlternativesNative', 'yingzhao-leaf-alternatives-result.json'),
    'yingzhao-spacing-natural': ('YingzhaoSpacingNaturalNative', 'yingzhao-spacing-natural-result.json'),
    'yingzhao-timing': ('YingzhaoTimingNative', 'yingzhao-timing-result.json'),
    'yingzhao-threat-review': ('YingzhaoThreatReviewNative', 'yingzhao-threat-review-result.json'),
    'yingzhao-edge-heldout': ('YingzhaoEdgeHeldoutNative', 'yingzhao-edge-heldout-result.json'),
    'yingzhao-edge-varied-model': ('YingzhaoEdgeVariedModelNative', 'yingzhao-edge-varied-model-result.json'),
    'yingzhao-edge-varied': ('YingzhaoEdgeVariedNative', 'yingzhao-edge-varied-result.json'),
    'yingzhao-expanded-sources': ('YingzhaoExpandedSourcesNative', 'yingzhao-expanded-sources-result.json'),
    'yingzhao-edge-counter-natural': ('YingzhaoEdgeCounterNaturalNative', 'yingzhao-edge-counter-natural-result.json'),
    'yingzhao-boundary-melee': ('YingzhaoBoundaryMeleeNative', 'yingzhao-boundary-melee-result.json'),
    'yingzhao-boundary-counter': ('YingzhaoBoundaryCounterNative', 'yingzhao-boundary-counter-result.json'),
    'yingzhao-boundary-wave': ('YingzhaoBoundaryWaveNative', 'yingzhao-boundary-wave-result.json'),
    'yingzhao-edge-conserve-learning': ('YingzhaoEdgeConserveLearningNative', 'yingzhao-edge-conserve-learning-result.json'),
    'yingzhao-edge-conserve': ('YingzhaoEdgeConserveNative', 'yingzhao-edge-conserve-result.json'),
    'yingzhao-companion-readback': ('YingzhaoCompanionReadbackNative', 'yingzhao-companion-readback-result.json'),
    'yingzhao-companion-review': ('YingzhaoCompanionReviewNative', 'yingzhao-companion-review-result.json'),
    'yingzhao-mentor-cover': ('YingzhaoMentorCoverNative', 'yingzhao-mentor-cover-result.json'),
    'yingzhao-summon-escape': ('YingzhaoSummonEscapeNative', 'yingzhao-summon-escape-result.json'),
    'yingzhao-spacing-lesson': ('YingzhaoSpacingLessonNative', 'yingzhao-spacing-lesson-result.json'),
    'yingzhao-dodge-spacing': ('YingzhaoDodgeSpacingNative', 'yingzhao-dodge-spacing-result.json'),
    'yingzhao-dodge-matrix': ('YingzhaoDodgeMatrixNative', 'yingzhao-dodge-matrix-result.json'),
    'ruins-cleanup': ('RuinsCleanupNative', 'ruins-cleanup-result.json'),
    'medical-cleanup': ('MedicalCleanupNative', 'medical-cleanup-result.json'),
    'settlement': ('SettlementNative', 'settlement-native-result.json'),
    'settlement-exit': ('SettlementExitNative', 'settlement-exit-result.json'),
    'yingzhao-boundary-movement': ('YingzhaoBoundaryMovementNative', 'yingzhao-boundary-movement-result.json'),
    'combat-backstep': ('CombatBackstepNative', 'combat-backstep-result.json'),
    'yingzhao-soak': ('YingzhaoSoakNative', 'yingzhao-soak-result.json'),
    'settlement-soak': ('SettlementSoakNative', 'settlement-soak-result.json'),
    'settlement-scene-cycle': ('SettlementSceneCycleNative', 'settlement-scene-cycle-result.json'),
    'trial-cleanup': ('TrialCleanupNative', 'trial-cleanup-result.json'),
    'pursuit-cleanup': ('PursuitCleanupNative', 'pursuit-cleanup-result.json'),
    'pursuit-group': ('PursuitGroupNative', 'pursuit-group-result.json'),
    'disarm-adoption': ('DisarmAdoptionNative', 'disarm-adoption-result.json'),
    'disarm-adoption-cold': ('DisarmAdoptionColdNative', 'disarm-adoption-cold-result.json'),
    'disarm-adoption-ui': ('DisarmAdoptionUINative', 'disarm-adoption-ui-result.json'),
    'ground-disarm': ('GroundDisarmNative', 'ground-disarm-result.json'),
    'ground-disarm-cold': ('GroundDisarmColdNative', 'ground-disarm-cold-result.json'),
    'ground-disarm-ownership': ('GroundDisarmOwnershipNative', 'ground-disarm-ownership-result.json'),
    'ground-disarm-budget': ('GroundDisarmBudgetNative', 'ground-disarm-budget-result.json'),
    'disarm-budget-advice': ('DisarmBudgetAdviceNative', 'disarm-budget-advice-result.json'),
    'ground-disarm-mouse': ('GroundDisarmMouse', 'ground-disarm-mouse-result.json'),
    'medium-flow': ('MediumYingzhaoFlowNative', 'medium-yingzhao-flow-result.json'),
    'small-combat': ('SmallYingzhaoCombatNative', 'small-yingzhao-combat-result.json'),
    'medium-pressure': ('MediumYingzhaoPressureNative', 'medium-yingzhao-pressure-result.json'),
    'disarm': ('DisarmPerformance', 'disarm-performance-result.json'),
    'attribution': ('CombatOptimizedAttribution', 'combat-optimized-attribution-result.json'),
    'lane-shots': ('CombatLaneShots', 'combat-lane-shots-result.json'),
    'lanes': ('CombatLaneStability', 'combat-lane-stability-result.json'),
    'aim-replay': ('CombatReleaseAimReplay', 'combat-release-aim-replay-result.json'),
    'training': ('CombatTrainingPerformance', 'combat-training-performance-result.json'),
    'hud': ('CombatHUDPerformance', 'combat-hud-performance-result.json'),
    'geometry': ('CombatStutterNativeParity', 'combat-stutter-native-parity-result.json'),
    'cycles': ('CombatOptimizedCycles', 'combat-optimized-cycles-result.json'),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime-manifest', required=True, type=Path)
    parser.add_argument('--test', choices=TESTS, required=True)
    parser.add_argument('--package-root', type=Path, help='Run the verified candidate binary and bundled game/assets; test harness remains external')
    parser.add_argument('--evidence', type=Path, required=True, help='New output directory; must not exist')
    parser.add_argument('--result-name', help='Separate JSON result for entries supporting qaResultName')
    parser.add_argument('--timeout', type=int, default=1200)
    parser.add_argument('--sample-rss', action='store_true', help='Sample native process RSS every second outside the engine')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    metadata = json.loads(args.runtime_manifest.read_text())
    if metadata.get('status') != 'built' or metadata.get('luaOptimizationFlags', [])[-1:] != ['-O3']:
        parser.error('Manifest does not prove an optimized completed build')
    binary = Path(metadata['binary']).resolve()
    engine = Path(metadata['engine']).resolve()
    game_root, engine_assets, package_record = root, engine/'Assets', None
    if args.package_root:
        package_root = args.package_root.resolve()
        package_manifest = json.loads((package_root/'package-manifest.json').read_text())
        if package_manifest.get('sourceRuntime', {}).get('binarySha256') != metadata['binarySha256']:
            parser.error('Candidate runtime provenance differs from the runtime manifest')
        for row in package_manifest['files']:
            path = (package_root/row['path']).resolve()
            if not path.is_relative_to(package_root) or not path.is_file() or path.stat().st_size != row['bytes'] or hashlib.sha256(path.read_bytes()).hexdigest() != row['sha256']:
                parser.error('Candidate file no longer matches its manifest: '+row['path'])
        app = package_root/'LingShuQiYuan.app'
        binary, engine_assets = app/'Contents/MacOS/Dora', app/'Contents/Resources'
        game_root = engine_assets/'LSD'
        if not (game_root/'init.lua').is_file():
            parser.error('Candidate game entry missing')
        package_record = {'root':str(package_root),'gameRoot':str(game_root),'filesVerified':len(package_manifest['files']),'externalHarness':True,'defaultAppBootstrap':False}
    elif hashlib.sha256(binary.read_bytes()).hexdigest() != metadata['binarySha256']:
        parser.error('Runtime binary no longer matches its manifest')
    if subprocess.run(['pgrep', '-f', '[.]app/Contents/MacOS/Dora'], capture_output=True).returncode == 0:
        parser.error('Another native Dora process is active; finish it before QA')
    evidence = args.evidence.resolve()
    evidence.mkdir(parents=True, exist_ok=False)
    base = Path(tempfile.mkdtemp(prefix='lsd-combat-qa-', dir='/private/tmp'))
    assets, writable = base / 'assets', base / 'save'
    (assets / 'Script').mkdir(parents=True)
    writable.mkdir()
    for name in ['Audio', 'Doc', 'Font', 'Image', 'Shader', 'dora-wa', 'www', 'LICENSES', 'gamecontrollerdb.txt']:
        source = engine_assets / name
        if source.exists():
            (assets / name).symlink_to(source, target_is_directory=source.is_dir())
    (assets / 'Script/Lib').symlink_to(engine_assets / 'Script/Lib', target_is_directory=True)
    test, result_name = TESTS[args.test]
    if args.result_name:
        if not re.fullmatch(r'[a-z0-9][a-z0-9-]*[.]json', args.result_name):
            parser.error('Result name must be a simple lowercase JSON filename')
        if 'local entry,qaResultName=...' not in (root/'Test'/(test+'.lua')).read_text():
            parser.error('This test does not support a separate result name')
        result_name = args.result_name
    result = root / 'Test' / result_name
    if result.exists():
        shutil.copyfile(result, evidence / 'previous-result.json')
    result.write_text(json.dumps({'status': 'RUNNING', 'runnerStarted': time.time()}))
    quote = lambda value: json.dumps(str(value), ensure_ascii=False)
    search = [game_root, game_root/'Script', game_root/'Spine', game_root/'Image', game_root/'Font', engine_assets/'Script/Lib']
    isolation_file = writable/'package-isolation.json'
    guard = ''
    if args.package_root:
        guard = f"""
local permitted={{{','.join(quote(p) for p in search)}}}
local resourceRoot={quote(engine_assets)}
local audit={{blockedSearchPaths={{}},modules={{}}}}
local function inside(path) return path==resourceRoot or path:sub(1,#resourceRoot+1)==resourceRoot..'/' end
local content=getmetatable(D.Content)
local insert=content.insertSearchPath
content.insertSearchPath=function(self,index,path)
 local resolved=self:getFullPath(path)
 if not inside(resolved)then audit.blockedSearchPaths[#audit.blockedSearchPaths+1]=path;return end
 return insert(self,index,resolved)
end
local searchers=package.loaders or package.searchers
for index,searcher in ipairs(searchers)do
 searchers[index]=function(name)
  D.Content.searchPaths=permitted
  local loader,extra=searcher(name)
  if type(loader)=='function'then
   local source=debug.getinfo(loader,'S').source
   local filename=name:gsub('%.','/')..'.lua'
   local resolved=D.Content:exist(filename)and D.Content:getFullPath(filename)or nil
   if source:sub(1,1)=='@'and D.Content:exist(source:sub(2))then resolved=D.Content:getFullPath(source:sub(2))end
   assert(not resolved or inside(resolved),'Package loader escaped resource root: '..tostring(resolved))
   audit.modules[name]={{loaderSource=source,resolvedFile=resolved}}
  end
  return loader,extra
 end
end
local function saveIsolation()
 audit.searchPaths=D.Content.searchPaths
 D.Content:save({quote(isolation_file)},D.json.encode(audit,false,true))
end
"""
    bootstrap = f"""local D=require('Dora')
D.Content.writablePath={quote(writable)}
D.Content.searchPaths={{{','.join(quote(p) for p in search)}}}
{guard}
D.thread(function()D.sleep(1);while true do
 local s=D.Content:load({quote(result)});local ok,r=pcall(D.json.decode,s or '')
 if ok and r and (r.status=='PASS' or r.status=='FAIL')then
  {'saveIsolation()' if args.package_root else ''}
  D.App:shutdown();return
 end
 D.sleep(1)
end end)
local path={quote(root / 'Test' / (test + '.lua'))}
local ok,why=xpcall(function()
 assert(load(D.Content:load(path),'@'..path))({quote(root / 'Test' / test)},{quote(result_name)})
end,debug.traceback)
if not ok then D.Content:save({quote(result)},D.json.encode({{status='FAIL',error=why}},false,true))end
"""
    (assets / 'Script/init.lua').write_text(bootstrap)
    record = {'runtime': metadata, 'test': test, 'workDirectory': str(base), 'started': time.time(),
              'testSha256': hashlib.sha256((root/'Test'/(test+'.lua')).read_bytes()).hexdigest(),
              'status': 'RUNNING', 'package':package_record}
    # Freeze the game implementation fingerprint used by this run, excluding
    # mutable QA results and binary art. Resource-specific tests have manifests.
    record['luaSources'] = {str(p.relative_to(game_root)): hashlib.sha256(p.read_bytes()).hexdigest()
                            for p in sorted((game_root/'Script').rglob('*.lua'))}
    record['uiLuaSources'] = {str(p.relative_to(game_root)): hashlib.sha256(p.read_bytes()).hexdigest()
                              for p in sorted((game_root/'UI').rglob('*.lua'))}
    (evidence/'run.json').write_text(json.dumps(record, ensure_ascii=False, indent=2))
    try:
        with (evidence/'process.log').open('w') as log:
            if args.sample_rss:
                with subprocess.Popen([str(binary), '--asset', str(assets)], stdout=log, stderr=subprocess.STDOUT) as process:
                    record['pid'] = process.pid
                    samples = []
                    started = time.monotonic()
                    try:
                        while process.poll() is None:
                            if time.monotonic() - started >= args.timeout:
                                raise subprocess.TimeoutExpired(process.args, args.timeout)
                            probe = subprocess.run(['ps', '-o', 'rss=', '-p', str(process.pid)], capture_output=True, text=True, timeout=5)
                            if probe.returncode == 0 and probe.stdout.strip().isdigit():
                                samples.append({'elapsed': time.monotonic()-started, 'rssKB': int(probe.stdout.strip())})
                            try:
                                process.wait(timeout=1)
                            except subprocess.TimeoutExpired:
                                pass
                    finally:
                        if process.poll() is None:
                            process.kill()
                            process.wait()
                        (evidence/'rss.json').write_text(json.dumps({'pid': process.pid, 'samples': samples}, indent=2))
            else:
                process = subprocess.run([str(binary), '--asset', str(assets)], stdout=log,
                                         stderr=subprocess.STDOUT, timeout=args.timeout)
        data = json.loads(result.read_text())
        after_sources = {str(p.relative_to(game_root)): hashlib.sha256(p.read_bytes()).hexdigest()
                         for p in sorted((game_root/'Script').rglob('*.lua'))}
        after_ui_sources = {str(p.relative_to(game_root)): hashlib.sha256(p.read_bytes()).hexdigest()
                            for p in sorted((game_root/'UI').rglob('*.lua'))}
        record['uiSourcesUnchanged'] = after_ui_sources == record['uiLuaSources']
        record['gameSourcesUnchanged'] = after_sources == record['luaSources'] and record['uiSourcesUnchanged']
        if not record['gameSourcesUnchanged']:
            raise RuntimeError('Game scripts changed during QA; results need a fresh run')
        if hashlib.sha256((root/'Test'/(test+'.lua')).read_bytes()).hexdigest() != record['testSha256']:
            raise RuntimeError('Active test changed during QA')
        if args.package_root:
            audit = json.loads(isolation_file.read_text())
            shutil.copyfile(isolation_file, evidence/'package-isolation.json')
            origins = {}
            modules = audit['modules']
            # Lua encodes an empty table as []; retain the required game-module proof below.
            if modules == []:
                modules = {}
            if not isinstance(modules, dict):
                raise RuntimeError('Invalid package module audit')
            for name, row in modules.items():
                if row.get('resolvedFile'):
                    module_file = Path(row['resolvedFile']).resolve()
                    if not module_file.is_relative_to(engine_assets):
                        raise RuntimeError('Loaded module escaped candidate: '+str(module_file))
                    origins[name] = str(module_file)
            if not any(Path(path).is_relative_to(game_root/'Script') or Path(path).is_relative_to(game_root/'UI') for path in origins.values()):
                raise RuntimeError('No candidate game module loading was proven')
            if any(not Path(path).resolve().is_relative_to(engine_assets) for path in audit['searchPaths']):
                raise RuntimeError('Runtime search paths escaped candidate')
            for row in package_manifest['files']:
                package_file = package_root/row['path']
                if package_file.stat().st_size != row['bytes'] or hashlib.sha256(package_file.read_bytes()).hexdigest() != row['sha256']:
                    raise RuntimeError('Candidate changed during QA: '+row['path'])
            record['packageIsolation'] = {'verified':True,'moduleFiles':origins,'blockedSearchPaths':audit['blockedSearchPaths'],'filesVerifiedAfter':len(package_manifest['files'])}
        # A natural defeat still needs source/isolation proof; keep test status
        # strict and archive the full result instead of skipping post-run audits.
        runtime_errors = runtime_error_lines((evidence/'process.log').read_text(errors='replace'))
        record['runtimeErrorCount'] = len(runtime_errors)
        record['runtimeErrorLines'] = runtime_errors[:20]
        if runtime_errors:
            raise RuntimeError('Native runtime errors were logged; result cannot pass: '+runtime_errors[0])
        if process.returncode != 0 or data.get('status') != 'PASS':
            raise RuntimeError(f"QA failed: exit={process.returncode}, status={data.get('status')}, error={data.get('error')}")
        record['status'] = 'PASS'
    except Exception as error:
        record.update(status='FAIL', error=str(error))
        raise
    finally:
        record['finished'] = time.time()
        if result.exists():
            shutil.copyfile(result, evidence/'result.json')
        (evidence/'run.json').write_text(json.dumps(record, ensure_ascii=False, indent=2))
    print(json.dumps({'status': record['status'], 'evidence': str(evidence)}, ensure_ascii=False))


if __name__ == '__main__':
    main()
