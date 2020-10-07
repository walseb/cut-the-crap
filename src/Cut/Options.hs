{-# LANGUAGE DataKinds        #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeOperators    #-}
{-# LANGUAGE DeriveAnyClass #-}

-- | This module defines which options exists, and provides
--   functions for parsing cli options.
module Cut.Options
  ( parseProgram
  , specifyTracks
  , getOutFileName
  -- * Program options
  , ProgramOptions
  , gnerate_sub_prism
  , listen_cut_prism
  -- * fileio, deal with input output files
  , FileIO
  , lc_fileio
  , in_file
  , out_file
  , work_dir
  -- * listen cut, options for video editing by audio
  , ListenCutOptionsT
  , ListenCutOptions
  , seg_size
  , silent_treshold
  , detect_margin
  , voice_track
  , music_track
  , silent_duration
  , cut_noise
  , voice_track_map
  -- * input source prisms
  , InputSource
  , input_src_remote
  , input_src_local_file
  -- * defaults
  , simpleOptions
  )
where

import           Control.Lens hiding (argument)
import           Data.Generics.Product.Fields
import           Data.Generics.Sum
import qualified Data.Text                    as Text
import           Data.Text.Lens
import           GHC.Generics                 hiding (to)
import           Options.Applicative
import Network.URI

simpleFileIO :: (FileIO InputSource)
simpleFileIO = FileIO  { fi_inFile         = LocalFile "in.mkv"                      , fi_outFile        = "out.mkv"
                       , fi_workDir        = Nothing
                        }

-- type Lens s t a b = forall f. Functor f => (a -> f b) -> s -> f t
in_file :: Lens (FileIO a) (FileIO b) a b
in_file = field @"fi_inFile"

out_file :: Lens' (FileIO a) FilePath
out_file = field @"fi_outFile"

work_dir :: Lens' (FileIO a) (Maybe FilePath)
work_dir = field @"fi_workDir"

simpleOptions :: ListenCutOptionsT InputSource
simpleOptions = ListenCutOptions
                        { lc_fileIO = simpleFileIO
                        , lc_segmentSize    = _Just # def_seg_size
                        , lc_silentTreshold = _Just # def_silent
                        , lc_detectMargin   = _Just # def_margin
                        , lc_voiceTrack     = _Just # 2
                        , lc_musicTrack     = Nothing
                        , lc_silentDuration = _Just # def_duration
                        , lc_cutNoise       = def_cut_noise
                        }

getOutFileName :: ListenCutOptionsT a -> FilePath
getOutFileName = reverse . takeWhile ('/' /=) . reverse . view (lc_fileio . out_file)

-- | Deals with having an input file and a target output file
data FileIO a = FileIO
              { fi_inFile  :: a
              , fi_outFile :: FilePath
              , fi_workDir :: Maybe FilePath -- ^ for consistency (or debugging) we may want to specify this.
              }
  deriving (Show, Generic, Functor, Applicative)

type ListenCutOptions = ListenCutOptionsT FilePath

-- | Cut out by listening to sound options
data ListenCutOptionsT a = ListenCutOptions
                { lc_fileIO         :: FileIO a
                , lc_segmentSize    :: Maybe Int
                , lc_silentTreshold :: Maybe Double
                , lc_silentDuration :: Maybe Double
                , lc_detectMargin   :: Maybe Double
                , lc_voiceTrack     :: Maybe Int
                , lc_musicTrack     :: Maybe Int
                , lc_cutNoise       :: Bool
                }
  deriving (Show, Generic, Functor, Applicative)

data ProgramOptions a = ListenCut (ListenCutOptionsT a)
                    | GenerateSubtitles (FileIO a)
  deriving (Show, Generic, Functor, Applicative)

-- type Prism s t a b = forall p f. (Choice p, Applicative f) => p a (f b) -> p s (f t)
-- prism :: (b -> t) -> (s -> Either t a) -> Prism s t a b
listen_cut_prism :: Prism (ProgramOptions a) (ProgramOptions b) (ListenCutOptionsT a) (ListenCutOptionsT b)
listen_cut_prism = prism ListenCut (\case
  GenerateSubtitles b -> Left $ GenerateSubtitles b
  ListenCut x -> Right x
  )

gnerate_sub_prism :: Prism (ProgramOptions a)  (ProgramOptions b) (FileIO a) (FileIO b)
gnerate_sub_prism =
  prism GenerateSubtitles (\case
    ListenCut b -> Left $ ListenCut b
    GenerateSubtitles x -> Right x
  )

def_seg_size :: Int
def_seg_size = 20

def_margin :: Double
def_margin = 0.05

def_cut_noise :: Bool
def_cut_noise = False

def_silent :: Double
def_silent = 0.0001

def_duration :: Double
def_duration = 0.25

def_voice :: Int
def_voice = 1

lc_fileio :: Lens' (ListenCutOptionsT a) (FileIO a)
lc_fileio = field @"lc_fileIO"

seg_size :: Lens' (ListenCutOptionsT a) Int
seg_size = field @"lc_segmentSize" . non def_seg_size

detect_margin :: Lens' (ListenCutOptionsT a) Double
detect_margin = field @"lc_detectMargin" . non def_margin

silent_treshold :: Lens' (ListenCutOptionsT a) Double
silent_treshold = field @"lc_silentTreshold" . non def_silent

silent_duration :: Lens' (ListenCutOptionsT a) Double
silent_duration = field @"lc_silentDuration" . non def_duration

voice_track :: Lens' (ListenCutOptionsT a) Int
voice_track = field @"lc_voiceTrack" . non def_voice

music_track :: Lens' (ListenCutOptionsT a) (Maybe Int)
music_track = field @"lc_musicTrack"

cut_noise :: Lens' (ListenCutOptionsT a) Bool
cut_noise = field @"lc_cutNoise"

voice_track_map :: (ListenCutOptionsT a) -> Text.Text
voice_track_map = mappend "0:" . view (voice_track . to show . packed)

specifyTracks :: (ListenCutOptionsT a) -> [Text.Text]
specifyTracks options =
  [ "-map"
  , "0:0"
  , "-map"  -- then copy only the voice track
  , voice_track_map options
  ]

data InputSource = LocalFile FilePath
                 | Remote URI
                 deriving (Show, Generic)

input_src_local_file :: Prism' InputSource FilePath
input_src_local_file = _Ctor @"LocalFile"

input_src_remote :: Prism' InputSource URI
input_src_remote = _Ctor @"Remote"

readFileSource :: ReadM InputSource
readFileSource = eitherReader $
  \x ->
    maybe (Left "unlikely error") Right $
    (Remote <$> parseURI x) <|> Just (LocalFile x)

parseFile :: Parser (FileIO InputSource)
parseFile = FileIO
    <$> argument readFileSource (metavar "INPUT" <> help "The input video, either a file or a uri")
    <*> argument str (metavar "OUTPUT_FILE" <> help "The output name without format")
    <*> optional
          (option
            str
            (  long "workDir"
            <> help
                 "If specified will use this as temporary directory to store intermeidate files in, good for debugging. Needs to be absolute"
            )
          )

parseProgram :: Parser (ProgramOptions InputSource)
parseProgram =
  subparser $
    command "listen" (info (ListenCut <$> parseSound) $ progDesc "Cut out by listening to sound options. We listen for silences and cut out the parts that are silenced.")
    <>
    command "subtitles" (info (GenerateSubtitles <$> parseFile) $ progDesc "Generate subtiles for a video. This is an intermediate (but usefull) feature developed for recognizing human speech vs background noise.")

parseSound :: Parser (ListenCutOptionsT InputSource)
parseSound = ListenCutOptions
    <$> parseFile
    <*> optional
          (option
            auto
            (long "segmentSize" <> help "The size of video segments in minutes")
          )
    <*> optional
          (option
            auto
            (  long "silentTreshold"
            <> help
                 "The treshold for determining intersting sections, closer to zero is detects more audio (n: https://ffmpeg.org/ffmpeg-filters.html#silencedetect)"
            )
          )
    <*> optional
          (option
            auto
            (  long "silentDuration"
            <> help
                 "The duration before soemthing can be considered a silence (d: https://ffmpeg.org/ffmpeg-filters.html#silencedetect)"
            )
          )
    <*> optional
          (option
            auto
            (long "detectMargin" <> help "Margin seconds around detection")
          )
    <*> optional
          (option
            auto
            (long "voiceTrack" <> help "The track to detect the silences upon")
          )
    <*> optional
          (option auto (long "musicTrack" <> help "The track to integrate"))
    <*> switch
          (long "cutNoise" <> help "Whether to cut noise instead of silence")
