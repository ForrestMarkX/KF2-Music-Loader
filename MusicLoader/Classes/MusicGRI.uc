class MusicGRI extends ReplicationInfo;

var MusicTrackStruct CurrentMusicTrack;
var AudioComponent MusicCompCue;
var KFGameReplicationInfo GRI;
var class<KFGameInfo> KFGameClass;
var bool bWaveIsActive;
var byte UpdateCounter, TimerCount;
var KFMusicTrackInfo CurrentTrackInfo;

replication
{
	if( true )
		GRI, KFGameClass;
}

simulated function UpdateMusicTrack( KFMusicTrackInfo NextMusicTrackInfo, bool bPlayStandardTrack )
{
	local KFMusicTrackInfo_Custom CustomInfo;
	local SoundCue CurrentTrack;
	local MusicTrackStruct Music;
	
	ForceStopAkMusic();
	ForceStopMusic(CurrentMusicTrack.FadeOutTime);
	
	CurrentTrackInfo = NextMusicTrackInfo;
	CustomInfo = KFMusicTrackInfo_Custom(NextMusicTrackInfo);
	if( CustomInfo == None )
		return;
		
	// Hate this but if not done then the original GRI version overwrites this one.
	SetTimer( 0.25, true, nameof(ShowMusicMessage) );
		
	if( CustomInfo.bIsAkEvent )
	{
		PlayAkSoundTrack(CustomInfo);
		return;
	}
	
	if( bPlayStandardTrack )
		CurrentTrack = SoundCue(CustomInfo.StandardSong);
	else CurrentTrack = SoundCue(CustomInfo.InstrumentalSong);
	
	GRI.CurrentMusicTrackInfo = CustomInfo;
	
	CurrentTrack.SoundClass = 'Music';
	Music.TheSoundCue = CurrentTrack;
	Music.FadeInTime = CustomInfo.FadeInTime;
	Music.FadeOutTime = 0.5f;

	PlaySoundTrack(Music);
	GRI.bPendingMusicTrackChange = false;
	GRI.MusicComp = None;
}

simulated function ShowMusicMessage()
{
	if( ++TimerCount == 2 )
	{
		TimerCount = 0;
		ClearTimer( nameof(ShowMusicMessage) );
	}
	
	GetALocalPlayerController().TeamMessage(GetALocalPlayerController().PlayerReplicationInfo,CurrentTrackInfo.TrackName$" -- "$CurrentTrackInfo.ArtistName,'Music');
}

simulated function ForceStopAkMusic()
{
	if( GRI.MusicComp != None )
		GRI.MusicComp.StopEvents();
}

simulated function ForceStopMusic(optional float FadeOutTime=1.0f)
{
	if( MusicCompCue!=None )
	{
		MusicCompCue.FadeOut(FadeOutTime,0.0);
		MusicCompCue = None;
	}
}

simulated function PlayAkSoundTrack(KFMusicTrackInfo_Custom CustomInfo)
{
	local KFMusicTrackInfo ModdedTrack;
	
	ModdedTrack = New(None) class'KFMusicTrackInfo';
	ModdedTrack.StandardTrack = AkEvent(CustomInfo.StandardSong);
	ModdedTrack.InstrumentalTrack = AkEvent(CustomInfo.InstrumentalSong);
	ModdedTrack.TrackName = CustomInfo.TrackName;
	ModdedTrack.ArtistName = CustomInfo.ArtistName;
	
	GRI.ForceNewMusicTrack(ModdedTrack);
}

simulated function PlaySoundTrack(MusicTrackStruct Music)
{
	local AudioComponent A;
	
	A = WorldInfo.CreateAudioComponent(Music.TheSoundCue,false,false,false,,false);
	if( A!=None )
	{
		A.bAutoDestroy = true;
		A.bShouldRemainActiveIfDropped = true;
		A.bIsMusic = true;
		A.bAutoPlay = Music.bAutoPlay;
		A.bIgnoreForFlushing = Music.bPersistentAcrossLevels;
		A.FadeIn( Music.FadeInTime, Music.FadeInVolumeLevel );
	}

	MusicCompCue = A;
	CurrentMusicTrack = Music;
}

simulated function PlayNewMusicTrack( optional bool bGameStateChanged, optional bool bForceAmbient )
{
    local KFMapInfo             KFMI;
    local KFMusicTrackInfo      NextMusicTrackInfo;
    local bool                  bLoop;
	local bool					bPlayActionTrack;
	
    if ( class'KFGameEngine'.static.CheckNoMusic() )
        return;

	//Required or else on servers the first waves action music never starts
	bPlayActionTrack = (!bForceAmbient && bWaveIsActive);
	
    if( bGameStateChanged )
    {
        if( bPlayActionTrack )
        {
            if( KFGameClass.default.ActionMusicDelay > 0 )
            {
                SetTimer( KFGameClass.default.ActionMusicDelay, false, nameof(PlayNewMusicTrack) );
                return;
            }
        }
    }
    else if( GRI.CurrentMusicTrackInfo != none )
        bLoop = GRI.CurrentMusicTrackInfo.bLoop;

    if( bLoop || GRI.IsFinalWave() )
        NextMusicTrackInfo = GRI.CurrentMusicTrackInfo;
    else
    {
        KFMI = KFMapInfo(WorldInfo.GetMapInfo());
        if ( KFMI != none )
            NextMusicTrackInfo = KFMI.GetNextMusicTrackByGameIntensity(bPlayActionTrack, GRI.MusicIntensity);
        else NextMusicTrackInfo = class'KFMapInfo'.static.StaticGetRandomTrack(bPlayActionTrack);
    }
	
	UpdateMusicTrack(NextMusicTrackInfo, KFGameEngine(Class'Engine'.static.GetEngine()).bMusicVocalsEnabled);
}

simulated function Tick(float DT)
{
	if ( WorldInfo.NetMode == NM_DedicatedServer )
		return;
		
	// I hate this so much but it's the only way to stop the original GRI from spamming songs
	if( MusicCompCue != None )
	{
		GRI.bPendingMusicTrackChange = false;
		GRI.MusicComp = None;
	}
		
	if( GRI.bMatchIsOver && MusicCompCue != None )
		ForceStopMusic(0.5f);
	
	if( bWaveIsActive != GRI.bWaveIsActive )
	{
		bWaveIsActive = GRI.bWaveIsActive;
		if( !GRI.IsFinalWave() )
			PlayNewMusicTrack( true );
	}
	
	if( ++UpdateCounter == 30 )
	{
		UpdateCounter = 0;
		if( MusicCompCue != None )
		{
			if( !MusicCompCue.IsPlaying() )
				PlayNewMusicTrack();
			else if( GRI.IsFinalWave() )
				ForceStopMusic(class<KFGameInfo>(GRI.GameClass).default.ActionMusicDelay);
		}
	}
}

simulated function ForceStartMusic()
{	
	if( GRI == None )
	{
		SetTimer(0.1f, false, nameOf(ForceStartMusic));
		return;
	}
	
	PlayNewMusicTrack(false, !bWaveIsActive);
}

defaultproperties
{
	bAlwaysRelevant=True
}