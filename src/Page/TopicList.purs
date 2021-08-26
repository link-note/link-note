module LinkNote.Page.TopicList where

import Prelude

import Data.Maybe (Maybe(..))
import Data.UUID as UUID
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML (HTML)
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import LinkNote.Capability.Navigate (class Navigate, navigate)
import LinkNote.Capability.Now (class Now, now)
import LinkNote.Capability.Resource.Note (class ManageNote)
import LinkNote.Capability.Resource.Topic (class ManageTopic, createTopic, getTopicByName, getTopics)
import LinkNote.Component.HTML.Utils (buttonClass, css, inputClass, safeHref)
import LinkNote.Data.Data (Topic)
import LinkNote.Data.Route as LR
import LinkNote.Data.Route as Route
import Web.UIEvent.KeyboardEvent as KE

type Input = Unit

type State = { 
    newTopicName :: String
    , topicList :: Array Topic
}

data Action = 
  ChangeNewTopicName String
  | EnterTopic
  | UpdateTopicList
  | HandleKeyUp KE.KeyboardEvent

render :: forall cs m. State -> H.ComponentHTML Action cs m
render st =
  HH.section_ [
    HH.div_ [
      HH.input [ 
        inputClass "mr-4"
        , HP.value st.newTopicName
        , HE.onValueChange \topicName -> ChangeNewTopicName topicName 
        , HE.onKeyUp HandleKeyUp
        ]
      , HH.button [ buttonClass "", HE.onClick \_ -> EnterTopic ] [HH.text "进入主题"]
    ] 
    , HH.ul_ $ st.topicList <#> renderItem
  ]

renderItem :: forall i p. Topic -> HTML i p
renderItem  topic  =
    HH.li_
      [ HH.a [ css "topic-item"
          , safeHref $ LR.Topic topic.id
          ]
          [ HH.text topic.name ]
      ]

initialState :: forall  a. a -> State
initialState _ = { 
  newTopicName : ""
  , topicList : []
}

component :: forall q  o m. 
  MonadAff m => 
  Now m => 
  ManageNote m =>
  Navigate m =>
  ManageTopic m =>
  H.Component q Input o m
component = H.mkComponent
    { 
      initialState
    , render
    , eval: H.mkEval H.defaultEval { 
        handleAction = handleAction
        , initialize = Just UpdateTopicList
      }
    }
  where
    handleAction = case _ of
      ChangeNewTopicName newTopicName -> do 
        H.modify_ _ { newTopicName = newTopicName}
      EnterTopic -> do
        newTopicName <- H.gets _.newTopicName
        mbTopic <- getTopicByName newTopicName
        case mbTopic of 
          Just topic -> navigate $ Route.Topic topic.id
          Nothing -> do
            uuid <- H.liftEffect UUID.genUUID 
            let id = "topic-" <> UUID.toString uuid
            nowTime <- now
            let topic = {
              id : id
              , name : newTopicName
              , created : nowTime
              , updated : nowTime
              , noteIds : []
            }
            createTopic topic
            navigate $ Route.Topic id
      UpdateTopicList -> do
        list <- getTopics
        H.modify_ _ { topicList = list }
      HandleKeyUp kev 
        | KE.key kev == "Enter"-> do
          handleAction EnterTopic
        | otherwise -> pure unit