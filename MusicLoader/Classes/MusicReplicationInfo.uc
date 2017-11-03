class MusicReplicationInfo extends ReplicationInfo;

var array<KFMusicTrackInfo> WaveMusic, TraderMusic;
var transient KFMapInfo KFMI;
var int CurrentIndex;

struct MusicRepInfo
{
	var AkBaseSoundObject InstrumentalSong, StandardSong; 
	var AkEvent StopEvent;
	var bool bIsAkEvent, bLoop;
	var float FadeInTime, MinGameIntensityLevel, MaxGameIntensityLevel;
	var name TrackName, ArtistName, AlbumName;
};

replication
{
	if( true )
		KFMI;
}

function UpdateClientMusic()
{
	ClientEmptyMusicInfo();
    SetTimer(0.05f, true, nameof(UpdateWaveMusic));
}

function UpdateWaveMusic()
{
	local MusicRepInfo MusicInfo;
	local KFMusicTrackInfo_Custom MusicObject;
	
    if (CurrentIndex < WaveMusic.Length)
    {
		MusicObject = KFMusicTrackInfo_Custom(WaveMusic[CurrentIndex]);
		
		MusicInfo.InstrumentalSong = MusicObject.InstrumentalSong;
		MusicInfo.StandardSong = MusicObject.StandardSong;
		MusicInfo.FadeInTime = MusicObject.FadeInTime;
		MusicInfo.bIsAkEvent = MusicObject.bIsAkEvent;
		MusicInfo.StopEvent = MusicObject.StopEvent;
		MusicInfo.MinGameIntensityLevel = MusicObject.MinGameIntensityLevel;
		MusicInfo.MaxGameIntensityLevel = MusicObject.MaxGameIntensityLevel;
		MusicInfo.AlbumName = MusicObject.AlbumName;
		MusicInfo.bLoop = MusicObject.bLoop;
		MusicInfo.TrackName = MusicObject.TrackName;
		MusicInfo.ArtistName = MusicObject.ArtistName;
		
		ClientSetMusic(MusicInfo, false);
        ++CurrentIndex;
    }
    else
    {
		CurrentIndex = 0;
        ClearTimer(nameof(UpdateWaveMusic));
		SetTimer(0.05f, true, nameof(UpdateTraderMusic));
    }
}

function UpdateTraderMusic()
{
	local MusicRepInfo MusicInfo;
	local KFMusicTrackInfo_Custom MusicObject;
	
    if (CurrentIndex < TraderMusic.Length)
    {
		MusicObject = KFMusicTrackInfo_Custom(TraderMusic[CurrentIndex]);
		
		MusicInfo.InstrumentalSong = MusicObject.InstrumentalSong;
		MusicInfo.StandardSong = MusicObject.StandardSong;
		MusicInfo.FadeInTime = MusicObject.FadeInTime;
		MusicInfo.bIsAkEvent = MusicObject.bIsAkEvent;
		MusicInfo.StopEvent = MusicObject.StopEvent;
		MusicInfo.MinGameIntensityLevel = MusicObject.MinGameIntensityLevel;
		MusicInfo.MaxGameIntensityLevel = MusicObject.MaxGameIntensityLevel;
		MusicInfo.AlbumName = MusicObject.AlbumName;
		MusicInfo.bLoop = MusicObject.bLoop;
		MusicInfo.TrackName = MusicObject.TrackName;
		MusicInfo.ArtistName = MusicObject.ArtistName;
		
		ClientSetMusic(MusicInfo, true);
        ++CurrentIndex;
    }
    else
    {
        ClearTimer(nameof(UpdateTraderMusic));
		FinishMusicRep();
		SetTimer(3, false, nameof(Destroy));
    }
}

reliable client function ClientEmptyMusicInfo()
{
	KFMI.ActionMusicTracks.Length = 0;
	KFMI.AmbientMusicTracks.Length = 0;
}

reliable client function ClientSetMusic(MusicRepInfo Info, bool bTraderMusic)
{
	local KFMusicTrackInfo_Custom MusicInfo;
	
	MusicInfo = CreateMusicObject(Info);
	if( bTraderMusic )
		KFMI.AmbientMusicTracks.AddItem(MusicInfo);
	else KFMI.ActionMusicTracks.AddItem(MusicInfo);
}

reliable client function FinishMusicRep()
{  
	local MusicGRI GRI;
	
	foreach AllActors(class'MusicGRI',GRI)
		break;
	
	GRI.ForceStartMusic();
}

simulated function KFMusicTrackInfo_Custom CreateMusicObject(MusicRepInfo Info)
{
	local KFMusicTrackInfo_Custom Track;
	
	Track = new(None) class'KFMusicTrackInfo_Custom';
	Track.FadeInTime = Info.FadeInTime;
	Track.bIsAkEvent = Info.bIsAkEvent;
	Track.InstrumentalSong = Info.InstrumentalSong;
	Track.StandardSong = Info.StandardSong;
	Track.StopEvent = Info.StopEvent;
	Track.MinGameIntensityLevel = Info.MinGameIntensityLevel;
	Track.MaxGameIntensityLevel = Info.MaxGameIntensityLevel;
	Track.AlbumName = Info.AlbumName;
	Track.bLoop = Info.bLoop;
	Track.TrackName = Info.TrackName;
	Track.ArtistName = Info.ArtistName;
	
	Track.InstrumentalTrack = AkEvent'WW_MACT_Default.Stop_MACT_Z_ActionFall';
	Track.StandardTrack = AkEvent'WW_MACT_Default.Stop_MACT_Z_ActionFall';
	
	return Track;
}

defaultproperties
{
	bAlwaysRelevant=false
	bOnlyRelevantToOwner=true
}