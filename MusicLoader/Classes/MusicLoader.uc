class MusicLoader extends KFMutator
	DependsOn(ML_WebAdmin_UI)
	config(Music);
	
struct RepInfoS
{
    var MusicReplicationInfo MRI;
    var KFPlayerController KFPC;
};

struct strictconfig MusicInfo
{
    var config string Instrumental, Vocal;
	var config name Name, Artist;
	var config bool bLoop;
	var AkEvent StopEvent;
	var float MinGameIntensityLevel, MaxGameIntensityLevel;
	var name AlbumName;
	
	structdefaultproperties
	{
		AlbumName="???"
		MinGameIntensityLevel=0.0
		MaxGameIntensityLevel=1.0
	}
};
	
var array<FWebAdminConfigInfo> 		WebConfigs;
var array<Object> 			   		ExternalObjs;
	
var config array<MusicInfo> 	    WaveMusic, TraderMusic;
var config int 					    ConfigVer;

var transient MusicGRI 				EGRI;
var transient KFMapInfo 			KFMI;

var array<RepInfoS> 				MusicReplicationInfos;

function InitMutator(string Options, out string ErrorMessage)
{
	local KFMusicTrackInfo_Custom 	Track;
	local KFMusicTrackInfo 			DefaultTrack;
	local AkBaseSoundObject 		VocalSong, InstrumentalSong;
	local array<MusicInfo> 			BaseWaveMusic, BaseTraderMusic;
	local MusicInfo 				Info;
	local MapMusicInfoObject 		MapMusic;
	local array<MusicInfo> 			LoadedWaveMusic, LoadedTraderMusic;
	local int 			   			i, Index;
	
	Super.InitMutator( Options, ErrorMessage );
	
	KFMI = KFMapInfo(WorldInfo.GetMapInfo());
	if( KFMI == None )
		return;
	
	for( i=0; i<KFMI.ActionMusicTracks.Length; ++i )
	{
		Info.Name = KFMI.ActionMusicTracks[i].StandardTrack.Name;
		Info.StopEvent = KFMI.ActionMusicTracks[i].StopEvent;
		Info.MinGameIntensityLevel = KFMI.ActionMusicTracks[i].MinGameIntensityLevel;
		Info.MaxGameIntensityLevel = KFMI.ActionMusicTracks[i].MaxGameIntensityLevel;
		Info.AlbumName = KFMI.ActionMusicTracks[i].AlbumName;
		
		BaseWaveMusic.AddItem(Info);
	}
	
	for( i=0; i<KFMI.AmbientMusicTracks.Length; ++i )
	{
		Info.Name = KFMI.AmbientMusicTracks[i].StandardTrack.Name;
		Info.StopEvent = KFMI.AmbientMusicTracks[i].StopEvent;
		Info.MinGameIntensityLevel = KFMI.AmbientMusicTracks[i].MinGameIntensityLevel;
		Info.MaxGameIntensityLevel = KFMI.AmbientMusicTracks[i].MaxGameIntensityLevel;
		Info.AlbumName = KFMI.AmbientMusicTracks[i].AlbumName;
		
		BaseTraderMusic.AddItem(Info);
	}
		
	if( ConfigVer <= 0 )
	{
		WaveMusic.Length = KFMI.ActionMusicTracks.Length;
		TraderMusic.Length = KFMI.AmbientMusicTracks.Length;
		
		for( i=0; i<KFMI.ActionMusicTracks.Length; ++i )
		{
			DefaultTrack = KFMI.ActionMusicTracks[i];
			WaveMusic[i].Vocal = DefaultTrack.StandardTrack.GetPackageName()$"."$DefaultTrack.StandardTrack.Name;
			WaveMusic[i].Instrumental = DefaultTrack.InstrumentalTrack.GetPackageName()$"."$DefaultTrack.InstrumentalTrack.Name;
			WaveMusic[i].Name = DefaultTrack.TrackName;
			WaveMusic[i].Artist = DefaultTrack.ArtistName;
			WaveMusic[i].bLoop = DefaultTrack.bLoop;
		}
		
		for( i=0; i<KFMI.AmbientMusicTracks.Length; ++i )
		{
			DefaultTrack = KFMI.AmbientMusicTracks[i];
			TraderMusic[i].Vocal = DefaultTrack.StandardTrack.GetPackageName()$"."$DefaultTrack.StandardTrack.Name;
			TraderMusic[i].Instrumental = DefaultTrack.InstrumentalTrack.GetPackageName()$"."$DefaultTrack.InstrumentalTrack.Name;
			TraderMusic[i].Name = DefaultTrack.TrackName;
			TraderMusic[i].Artist = DefaultTrack.ArtistName;
			TraderMusic[i].bLoop = DefaultTrack.bLoop;
		}
		
		ConfigVer = 1;
		SaveConfig();
	}
		
	KFMI.ActionMusicTracks.Length = 0;
	KFMI.AmbientMusicTracks.Length = 0;
	
	MapMusic = LoadMapMusicObject();
	LoadedWaveMusic = MapMusic != None ? MapMusic.WaveMusic : WaveMusic;
	LoadedTraderMusic = MapMusic != None ? MapMusic.TraderMusic : TraderMusic;
		
	for( i=0; i<LoadedWaveMusic.Length; ++i )
	{
		if( LoadedWaveMusic[i].Instrumental == ""  )
			continue;
			
		Track = new(None) class'KFMusicTrackInfo_Custom';
		if( Track == None )
			continue;
			
		if( LoadedWaveMusic[i].Vocal == "" )
			LoadedWaveMusic[i].Vocal = LoadedWaveMusic[i].Instrumental;
			
		VocalSong = AkBaseSoundObject(DynamicLoadObject(LoadedWaveMusic[i].Vocal, class'AkBaseSoundObject'));
		InstrumentalSong = AkBaseSoundObject(DynamicLoadObject(LoadedWaveMusic[i].Instrumental, class'AkBaseSoundObject'));
		
		AddLoadPackage(VocalSong);
		AddLoadPackage(InstrumentalSong);
		
		Track.FadeInTime = 5.f;
		Track.bIsAkEvent = InstrumentalSong.Class.Name == 'AkEvent';
		Track.InstrumentalSong = InstrumentalSong;
		Track.StandardSong = VocalSong == None ? InstrumentalSong : VocalSong;
		
		Track.InstrumentalTrack = AkEvent'WW_MACT_Default.Stop_MACT_Z_ActionFall';
		Track.StandardTrack = AkEvent'WW_MACT_Default.Stop_MACT_Z_ActionFall';
		
		Track.bLoop = LoadedWaveMusic[i].bLoop;
		Track.TrackName = LoadedWaveMusic[i].Name;
		Track.ArtistName = LoadedWaveMusic[i].Artist;
		
		Index = BaseWaveMusic.Find('Name', InstrumentalSong.Name);
		if( Index != INDEX_NONE )
		{
			Track.StopEvent = BaseWaveMusic[Index].StopEvent;
			Track.MinGameIntensityLevel = BaseWaveMusic[Index].MinGameIntensityLevel;
			Track.MaxGameIntensityLevel = BaseWaveMusic[Index].MaxGameIntensityLevel;
			Track.AlbumName = BaseWaveMusic[Index].AlbumName;
		}
		
		KFMI.ActionMusicTracks.AddItem(Track);
	}
	
	for( i=0; i<LoadedTraderMusic.Length; ++i )
	{
		if( LoadedTraderMusic[i].Instrumental == ""  )
			continue;
			
		Track = new(None) class'KFMusicTrackInfo_Custom';
		if( Track == None )
			continue;
			
		if( LoadedTraderMusic[i].Vocal == "" )
			LoadedTraderMusic[i].Vocal = LoadedTraderMusic[i].Instrumental;
			
		VocalSong = AkBaseSoundObject(DynamicLoadObject(LoadedTraderMusic[i].Vocal, class'AkBaseSoundObject'));
		InstrumentalSong = AkBaseSoundObject(DynamicLoadObject(LoadedTraderMusic[i].Instrumental, class'AkBaseSoundObject'));
		
		AddLoadPackage(VocalSong);
		AddLoadPackage(InstrumentalSong);
		
		Track.FadeInTime = 15.f;
		Track.bIsAkEvent = InstrumentalSong.Class.Name == 'AkEvent';
		Track.InstrumentalSong = InstrumentalSong;
		Track.StandardSong = VocalSong == None ? InstrumentalSong : VocalSong;
			
		Track.bLoop = LoadedTraderMusic[i].bLoop;
		Track.TrackName = LoadedTraderMusic[i].Name;
		Track.ArtistName = LoadedTraderMusic[i].Artist;
		
		Index = BaseTraderMusic.Find('Name', InstrumentalSong.Name);
		if( Index != INDEX_NONE )
		{
			Track.StopEvent = BaseTraderMusic[Index].StopEvent;
			Track.MinGameIntensityLevel = BaseTraderMusic[Index].MinGameIntensityLevel;
			Track.MaxGameIntensityLevel = BaseTraderMusic[Index].MaxGameIntensityLevel;
			Track.AlbumName = BaseTraderMusic[Index].AlbumName;
		}
		
		KFMI.AmbientMusicTracks.AddItem(Track);
	}
	
	SetTimer(0.1,false,'SetupExtendedGRI');
	
	if( WorldInfo.NetMode!=NM_StandAlone )
		SetTimer(0.1,false,'SetupWebAdmin');
}

function SetupExtendedGRI()
{
	EGRI = WorldInfo.Game.Spawn(class'MusicGRI');
	if( EGRI != None )
	{
		EGRI.GRI = KFGameReplicationInfo(WorldInfo.GRI);
		EGRI.KFGameClass = class<KFGameInfo>(WorldInfo.GRI.GameClass);
		if( WorldInfo.NetMode==NM_StandAlone )
			EGRI.PlayNewMusicTrack(false, true);
	}
}

function SetupWebAdmin()
{
	local WebServer W;
	local WebAdmin A;
	local ML_WebApp xW;
	local byte i;
	
	class'WebConnection'.default.MaxValueLength = Max(class'WebConnection'.default.MaxValueLength,510);
	class'WebConnection'.default.MaxLineLength = Max(class'WebConnection'.default.MaxLineLength,510);

	foreach AllActors(class'WebServer',W)
		break;
	
	if( W!=None )
	{
		for( i=0; (i<10 && A==None); ++i )
			A = WebAdmin(W.ApplicationObjects[i]);
		if( A!=None )
		{
			xW = new (None) class'ML_WebApp';
			xW.MyMutator = Self;
			A.addQueryHandler(xW);
		}
		else `Log("ML_WebApp ERROR: No valid WebAdmin application found!");
	}
	else `Log("ML_WebApp ERROR: No WebServer object found!");
}

function InitWebAdmin( ML_WebAdmin_UI UI )
{
	UI.AddSettingsPage("Main Music Loader",Class,WebConfigs,WebAdminGetValue,WebAdminSetValue);
}

// String output here is too long for the webadmin
final function string ParseMusicStruct( MusicInfo Info )
{
	return Info.Instrumental$","$Info.Vocal$","$Info.Name$","$Info.Artist$","$Info.bLoop;
}

function string WebAdminGetValue( name PropName, int ElementIndex )
{
	switch( PropName )
	{
	case 'WaveMusic':
		return (ElementIndex==-1 ? string(WaveMusic.Length) : ParseMusicStruct(WaveMusic[ElementIndex]));
	case 'TraderMusic':
		return (ElementIndex==-1 ? string(TraderMusic.Length) : ParseMusicStruct(TraderMusic[ElementIndex]));
	}
}

final function UpdateArray( out array<MusicInfo> Ar, int Index, const out string Value )
{
	if( Value=="#DELETE" )
		Ar.Remove(Index,1);
	else
	{
		if( Index>=Ar.Length )
			Ar.Length = Index+1;
		Ar[Index] = ParseMusicString(Value);
	}
}

function WebAdminSetValue( name PropName, int ElementIndex, string Value )
{
	switch( PropName )
	{
	case 'WaveMusic':
		UpdateArray(WaveMusic, ElementIndex, Value);
		break;
	case 'TraderMusic':
		UpdateArray(TraderMusic, ElementIndex, Value);
		break;
	default:
		return;
	}
	
	SaveConfig();
}

function MusicInfo ParseMusicString(string S)
{
	local MusicInfo Res;
	local int i;

	i = InStr(S,",");
	if( i==-1 )
		return Res;
	Res.Instrumental = Left(S,i);
	S = Mid(S,i+1);
	i = InStr(S,",");
	if( i==-1 )
		return Res;
	Res.Vocal = Left(S,i);
	S = Mid(S,i+1);
	i = InStr(S,",");
	if( i==-1 )
		return Res;
	Res.Name = name(Left(S,i));
	S = Mid(S,i+1);
	i = InStr(S,",");
	if( i==-1 )
		return Res;
	Res.Artist = name(Left(S,i));
	Res.bLoop = bool(Mid(S,i+1));
	return Res;
}

function MapMusicInfoObject LoadMapMusicObject()
{
	local array<string> Names;
	local string ObjectName;
	local int i;

	GetPerObjectConfigSections(class'MapMusicInfoObject', Names);
	for (i = 0; i < Names.Length; i++)
	{
		ObjectName = Left(Names[i], InStr(Names[i], " "));
		if( ObjectName ~= WorldInfo.GetMapName(true) )
			return New(None, ObjectName) class'MapMusicInfoObject';
	}
	
	return None;
}

final function AddLoadPackage( Object O )
{
	if( ExternalObjs.Find(O)==-1 )
		ExternalObjs.AddItem(O);
}

function NotifyLogin(Controller C)
{
	if( WorldInfo.NetMode!=NM_StandAlone && KFPlayerController(C) != None )
		CreateMRI(KFPlayerController(C));
		
    Super.NotifyLogin(C);
}

function NotifyLogout(Controller C)
{
	if( WorldInfo.NetMode!=NM_StandAlone && KFPlayerController(C) != None )
		DestroyMRI(KFPlayerController(C));
	
    Super.NotifyLogout(C);
}

function CreateMRI(KFPlayerController C)
{
    local RepInfoS Info;
    
    Info.MRI = Spawn(class'MusicReplicationInfo', C);
    Info.KFPC = C;
    
    MusicReplicationInfos.AddItem(Info);
	
	Info.MRI.KFMI = KFMI;
	Info.MRI.WaveMusic = KFMI.ActionMusicTracks;
	Info.MRI.TraderMusic = KFMI.AmbientMusicTracks;
	
	Info.MRI.UpdateClientMusic();
}

function DestroyMRI(KFPlayerController C)
{
    local int Index;
	
    Index = MusicReplicationInfos.Find('KFPC', C);
    if( Index == INDEX_NONE )
        return;
    
    if( MusicReplicationInfos[Index].MRI != None )
        MusicReplicationInfos[Index].MRI.Destroy();
    
    MusicReplicationInfos.Remove(Index, 1);
}

defaultproperties
{
	WebConfigs.Add((PropType=2,PropName="WaveMusic",UIName="Wave Music",UIDesc="The list of wave music to be loaded and added.",NumElements=-1))
	WebConfigs.Add((PropType=2,PropName="TraderMusic",UIName="Trader Music",UIDesc="The list of trader music to be loaded and added.",NumElements=-1))
}