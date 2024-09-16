provider "aws" {
  region = "us-east-1"
  access_key = ""
  secret_key = ""
}

resource "aws_iam_role" "amplify-role" {
  name = "AmplifyRoleSpotiguys"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["apigateway.amazonaws.com","amplify.amazonaws.com","lambda.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess-Amplify"
  ]
}

resource "aws_iam_role" "consumerRole" {
name   = "consumerRole"
assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": ["apigateway.amazonaws.com","lambda.amazonaws.com"]
     },
     "Effect": "Allow"
   }
 ]
}
EOF
managed_policy_arns = [
  "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
  "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
  "arn:aws:iam::aws:policy/AmazonKinesisFullAccess",
  "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole",
  "arn:aws:iam::aws:policy/service-role/AWSLambdaKinesisExecutionRole",
  "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  "arn:aws:iam::aws:policy/AmazonSNSFullAccess",
  "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  "arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator"
]
}

resource "aws_iam_role" "lambda_role" {
name   = "lambda_role"
assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": ["apigateway.amazonaws.com","lambda.amazonaws.com"]
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
managed_policy_arns = [
  "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  "arn:aws:iam::aws:policy/AWSLambda_FullAccess",
  "arn:aws:iam::aws:policy/AmazonKinesisFullAccess",
  "arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator",
  "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
]
}

resource "aws_iam_policy" "lambda_log_policy" {
  name = "lambda-log-policy"
  
  policy = jsonencode({
    "Version": "2012-10-17",
	"Statement": [
	  {
	    Action: [
		  "logs:CreateLogStream",
		  "logs:PutLogEvents"
		],
		Effect: "Allow",
		Resource: "arn:aws:logs:*:*:*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_role_log_policy_attachment" {
  role = aws_iam_role.lambda_role.id
  policy_arn = aws_iam_policy.lambda_log_policy.arn
}

resource "aws_iam_role_policy_attachment" "consumer_role_log_policy_attachment" {
  role = aws_iam_role.consumerRole.id
  policy_arn = aws_iam_policy.lambda_log_policy.arn
}

resource "aws_lambda_layer_version" "spotipy_layer" {
  filename = "spotipy.zip"
  layer_name = "spotipy_layer"
  
  compatible_runtimes = ["python3.9"]
}

resource "aws_lambda_permission" "gateway_execute_callback" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.CallbackLambda.function_name
    principal     = "apigateway.amazonaws.com"
	
	source_arn = "${aws_api_gateway_rest_api.Spotiguys.execution_arn}/*/*"
}

resource "aws_lambda_permission" "gateway_execute_producer" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.KinesisProducer.function_name
    principal     = "apigateway.amazonaws.com"
	
	source_arn = "${aws_api_gateway_rest_api.Spotiguys.execution_arn}/*/*"
}

resource "aws_lambda_permission" "gateway_execute_create_playlist" {
    statement_id = "AllowAPIGatewayInvoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.PostPlaylistLambda.function_name
    principal = "apigateway.amazonaws.com"
	
	source_arn = "${aws_api_gateway_rest_api.Spotiguys.execution_arn}/*/*"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "spotiguys-bucket-1-test"
  force_destroy = true
}

resource "aws_s3_bucket" "playlist-bucket" {
  bucket = "spotiguys-finished-playlist-bucket-test"
  force_destroy = true
}

resource "aws_lambda_function" "CallbackLambda" {
  filename = "callback.zip"
  function_name = "Callback_Function"
  role = aws_iam_role.lambda_role.arn
  handler = "callback.lambda_handler"
  runtime = "python3.9"
  
  timeout = 300
	
  layers = [aws_lambda_layer_version.spotipy_layer.arn]
}

resource "aws_lambda_function" "KinesisConsumer" {
  filename = "consumer.zip"
  function_name = "Kinesis_Consumer_Lambda"
  role = aws_iam_role.consumerRole.arn
  handler = "consumer.lambda_handler"
  runtime = "python3.9"
  
  timeout = 300
}

resource "aws_lambda_event_source_mapping" "consumer_mapping" {
  event_source_arn = aws_kinesis_stream.KinesisStream.arn
  function_name = aws_lambda_function.KinesisConsumer.arn
  starting_position = "LATEST"
}

resource "aws_lambda_function" "KinesisProducer" {
  filename = "producer.zip"
  function_name = "Kinesis_Producer_Lambda"
  role = aws_iam_role.lambda_role.arn
  handler = "producer.lambda_handler"
  runtime = "python3.9"
  
  timeout = 300
}

resource "aws_lambda_function" "PostPlaylistLambda" {
  filename = "playlist.zip"
  function_name = "Post_Playlist_Lambda"
  role = aws_iam_role.lambda_role.arn
  handler = "playlist.lambda_handler"
  runtime = "python3.9"
  
  timeout = 300

  layers = [aws_lambda_layer_version.spotipy_layer.arn]
}

resource "aws_api_gateway_rest_api" "Spotiguys" {
  name        = "Spotiguys_API"
  description = "API for spotiguys project"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

data "aws_arn" "certificate" {
  arn = "arn:aws:acm:us-east-1:094549249934:certificate/a02d1419-c8ec-43c8-ab04-f9de81c9f7d6"
}

resource "aws_api_gateway_domain_name" "domain_name" {
  domain_name = "api.spotiguys.tk"
  regional_certificate_arn = data.aws_arn.certificate.arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_route53_record" "dns_record" {
  name = aws_api_gateway_domain_name.domain_name.domain_name
  type = "A"
  zone_id = "Z081417317DDTP8URHMXA"

  alias {
    evaluate_target_health = true
    name = aws_api_gateway_domain_name.domain_name.regional_domain_name
    zone_id = aws_api_gateway_domain_name.domain_name.regional_zone_id
  }
}

resource "aws_api_gateway_base_path_mapping" "api_mapping" {
  api_id = aws_api_gateway_rest_api.Spotiguys.id
  stage_name = aws_api_gateway_deployment.login_deployment.stage_name
  domain_name = aws_api_gateway_domain_name.domain_name.domain_name
}

resource "aws_api_gateway_resource" "callback" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  parent_id   = aws_api_gateway_rest_api.Spotiguys.root_resource_id
  path_part   = "callback"
}

resource "aws_api_gateway_method" "get_callback" {
  rest_api_id   = aws_api_gateway_rest_api.Spotiguys.id
  resource_id   = aws_api_gateway_resource.callback.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.querystring.access_token" = true
  }
}

resource "aws_api_gateway_method_response" "callback_response" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_resource.callback.id
  http_method = aws_api_gateway_method.get_callback.http_method
  
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration" "lambda_callback" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_method.get_callback.resource_id
  http_method = aws_api_gateway_method.get_callback.http_method

  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.CallbackLambda.invoke_arn
  
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  
  credentials = aws_iam_role.lambda_role.arn
  
  request_templates = {
    "application/json" = <<EOF
	  #set($inputRoot = $input.path('$'))
	  {
		"access_token" : "$input.params('access_token')"
	  }
	EOF
  }
}

resource "aws_api_gateway_integration_response" "callback_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_resource.callback.id
  http_method = aws_api_gateway_method.get_callback.http_method
  status_code = aws_api_gateway_method_response.callback_response.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  
  depends_on = [
    aws_api_gateway_integration.lambda_callback
  ]
}

resource "aws_api_gateway_resource" "create_playlist" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  parent_id   = aws_api_gateway_rest_api.Spotiguys.root_resource_id
  path_part   = "create-playlist"
}

resource "aws_api_gateway_method" "get_create_playlist" {
  rest_api_id   = aws_api_gateway_rest_api.Spotiguys.id
  resource_id   = aws_api_gateway_resource.create_playlist.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.id" = true
  }
}

resource "aws_api_gateway_method_response" "create_playlist_resp" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_resource.create_playlist.id
  http_method = aws_api_gateway_method.get_create_playlist.http_method
  
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration" "lambda_producer" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_method.get_create_playlist.resource_id
  http_method = aws_api_gateway_method.get_create_playlist.http_method

  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.KinesisProducer.invoke_arn
  
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  
  credentials = aws_iam_role.lambda_role.arn
  
  request_templates = {
    "application/json" = <<EOF
	  #set($inputRoot = $input.path('$'))
	  {
		"id" : "$input.params('id')"
	  }
	EOF
  }
}

resource "aws_api_gateway_integration_response" "create_playlist_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_resource.create_playlist.id
  http_method = aws_api_gateway_method.get_create_playlist.http_method
  status_code = aws_api_gateway_method_response.create_playlist_resp.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  
  depends_on = [
    aws_api_gateway_integration.lambda_producer
  ]
}

resource "aws_api_gateway_resource" "me_info" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  parent_id   = aws_api_gateway_rest_api.Spotiguys.root_resource_id
  path_part   = "me"
}

resource "aws_api_gateway_method" "get_info" {
  rest_api_id   = aws_api_gateway_rest_api.Spotiguys.id
  resource_id   = aws_api_gateway_resource.me_info.id
  http_method   = "GET"
  authorization = "NONE"
      request_parameters = {
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_method_response" "info_response" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_resource.me_info.id
  http_method = aws_api_gateway_method.get_info.http_method
  status_code = "200"
     response_models = {
         "application/json" = "Empty"
    }
}

resource "aws_api_gateway_integration" "info_integration" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_method.get_info.resource_id
  http_method = aws_api_gateway_method.get_info.http_method

  integration_http_method = "GET"
  type                    = "HTTP"
  passthrough_behavior    = "WHEN_NO_MATCH"
  uri                     = "https://api.spotify.com/v1/me"
  request_parameters = {
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
  
  credentials = aws_iam_role.lambda_role.arn
}

resource "aws_api_gateway_integration_response" "info_int_response" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_resource.me_info.id
  http_method = aws_api_gateway_method.get_info.http_method
  status_code = aws_api_gateway_method_response.info_response.status_code
    response_templates = {
       "application/json" = ""
   }

  depends_on = [aws_api_gateway_integration.info_integration]
}

resource "aws_api_gateway_resource" "audio" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  parent_id   = aws_api_gateway_rest_api.Spotiguys.root_resource_id
  path_part   = "audio-features"
}

resource "aws_api_gateway_resource" "audio_id" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  parent_id   = aws_api_gateway_resource.audio.id
  path_part   = "{id}"
}


resource "aws_api_gateway_method" "get_audio" {
  rest_api_id   = aws_api_gateway_rest_api.Spotiguys.id
  resource_id   = aws_api_gateway_resource.audio_id.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.id" = true
	"method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_method_response" "audio_response" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_resource.audio_id.id
  http_method = aws_api_gateway_method.get_audio.http_method
  status_code = "200"
  response_models = {
         "application/json" = "Empty"
    }
}

resource "aws_api_gateway_integration" "audio_integration" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_method.get_audio.resource_id
  http_method = aws_api_gateway_method.get_audio.http_method

  integration_http_method = "GET"
  type                    = "HTTP"
  passthrough_behavior    = "WHEN_NO_MATCH"
  uri                     = "https://api.spotify.com/v1/audio-features/{id}"

      request_parameters = {
        "integration.request.path.id" = "method.request.path.id"
        "integration.request.header.Authorization" = "method.request.header.Authorization"
    }
  
  credentials = aws_iam_role.lambda_role.arn
}

resource "aws_api_gateway_integration_response" "audio_int_response" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_resource.audio_id.id
  http_method = aws_api_gateway_method.get_audio.http_method
  status_code = aws_api_gateway_method_response.audio_response.status_code

  depends_on = [aws_api_gateway_integration.audio_integration]
}

resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  parent_id   = aws_api_gateway_rest_api.Spotiguys.root_resource_id
  path_part   = "users"
}

resource "aws_api_gateway_resource" "user_id" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "{user-id}"
}

resource "aws_api_gateway_resource" "playlists_users" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  parent_id   = aws_api_gateway_resource.user_id.id
  path_part   = "playlists"
}

resource "aws_api_gateway_resource" "post_group_playlist" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  parent_id = aws_api_gateway_rest_api.Spotiguys.root_resource_id
  path_part = "post-playlist"
}

resource "aws_api_gateway_method" "post_group_method" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_resource.post_group_playlist.id
  http_method = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.access_token" = true
  }
}

resource "aws_api_gateway_method_response" "post_group_response" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_resource.post_group_playlist.id
  http_method = aws_api_gateway_method.post_group_method.http_method
  
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration" "post_group_integration" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_resource.post_group_playlist.id
  http_method = aws_api_gateway_method.post_group_method.http_method
  integration_http_method = "POST"
  type = "AWS"
  uri = aws_lambda_function.PostPlaylistLambda.invoke_arn
  
  credentials = aws_iam_role.lambda_role.arn
  
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  
  request_templates = {
    "application/json" = <<EOF
	  #set($inputRoot = $input.path('$'))
	  {
		"access_token" : "$input.params('access_token')"
	  }
	EOF
  }
}

resource "aws_api_gateway_integration_response" "post_group_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_resource.post_group_playlist.id
  http_method = aws_api_gateway_method.post_group_method.http_method
  status_code = aws_api_gateway_method_response.post_group_response.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  
  depends_on = [
    aws_api_gateway_integration.post_group_integration
  ]
}

resource "aws_api_gateway_method" "get_playlists" {
  rest_api_id   = aws_api_gateway_rest_api.Spotiguys.id
  resource_id   = aws_api_gateway_resource.playlists_users.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.user-id" = true
    "method.request.querystring.limit" = true
    "method.request.querystring.offset" = true
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_method_response" "get_playlists_response" {
    rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
    resource_id = aws_api_gateway_resource.playlists_users.id
    http_method = aws_api_gateway_method.get_playlists.http_method
    status_code = "200"
    response_models = {
         "application/json" = "Empty"
    }
}

resource "aws_api_gateway_method" "post_playlists" {
  rest_api_id   = aws_api_gateway_rest_api.Spotiguys.id
  resource_id   = aws_api_gateway_resource.playlists_users.id
  http_method   = "POST"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.user-id" = true
    "method.request.header.Authorization" = true
  }
}
	
resource "aws_api_gateway_method_response" "post_playlist_response" {
    rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
    resource_id = aws_api_gateway_resource.playlists_users.id
    http_method = aws_api_gateway_method.post_playlists.http_method
    status_code = "200"
    response_models = {
         "application/json" = "Empty"
    }
}

resource "aws_api_gateway_integration" "playlist_integration1" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_method.get_playlists.resource_id
  http_method = aws_api_gateway_method.get_playlists.http_method

  integration_http_method = "GET"
  type                    = "HTTP"
  passthrough_behavior    = "WHEN_NO_MATCH"
  uri                     = "https://api.spotify.com/v1/users/{user-id}/playlists"

      request_parameters = {
        "integration.request.path.user-id" = "method.request.path.user-id"
        "integration.request.header.Authorization" = "method.request.header.Authorization"
        "integration.request.querystring.limit" = "method.request.querystring.limit"
        "integration.request.querystring.offset" = "method.request.querystring.offset"
    }
  
  credentials = aws_iam_role.lambda_role.arn
}


resource "aws_api_gateway_integration_response" "get_playlist_int_resp" {
   rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
   resource_id = aws_api_gateway_resource.playlists_users.id
   http_method = aws_api_gateway_method.get_playlists.http_method
   status_code = aws_api_gateway_method_response.get_playlists_response.status_code
   response_templates = {
       "application/json" = ""
   }

   depends_on = [aws_api_gateway_integration.playlist_integration1]
}

resource "aws_api_gateway_integration" "playlist_integration2" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_method.post_playlists.resource_id
  http_method = aws_api_gateway_method.post_playlists.http_method

  integration_http_method = "POST"
  type                    = "HTTP"
  passthrough_behavior    = "WHEN_NO_MATCH"
  uri                     = "https://api.spotify.com/v1/users/{user-id}/playlists"

      request_parameters = {
        "integration.request.path.user-id" = "method.request.path.user-id"
        "integration.request.header.Authorization" = "method.request.header.Authorization"
    }
  
  credentials = aws_iam_role.lambda_role.arn
}

resource "aws_api_gateway_integration_response" "post_playlist_int_resp" {
   rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
   resource_id = aws_api_gateway_resource.playlists_users.id
   http_method = aws_api_gateway_method.post_playlists.http_method
   status_code = aws_api_gateway_method_response.post_playlist_response.status_code
   response_templates = {
       "application/json" = ""
   }

   depends_on = [aws_api_gateway_integration.playlist_integration2]
}

module "cors_callback" {
  source = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.Spotiguys.id
  api_resource_id = aws_api_gateway_resource.callback.id
}

module "cors_group_playlist" {
  source = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.Spotiguys.id
  api_resource_id = aws_api_gateway_resource.post_group_playlist.id
}

module "cors_create_playlist" {
  source = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.Spotiguys.id
  api_resource_id = aws_api_gateway_resource.create_playlist.id
}

resource "aws_api_gateway_resource" "playlists" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  parent_id   = aws_api_gateway_rest_api.Spotiguys.root_resource_id
  path_part   = "playlists"
}

resource "aws_api_gateway_resource" "playlist_id" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  parent_id   = aws_api_gateway_resource.playlists.id
  path_part   = "{playlist-id}"
}

resource "aws_api_gateway_resource" "tracks" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  parent_id   = aws_api_gateway_resource.playlist_id.id
  path_part   = "tracks"
}

resource "aws_api_gateway_method" "get_tracks" {
  rest_api_id   = aws_api_gateway_rest_api.Spotiguys.id
  resource_id   = aws_api_gateway_resource.tracks.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.playlist-id" = true
    "method.request.querystring.limit" = true
    "method.request.querystring.offset" = true
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_method_response" "tracks_response" {
    rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
    resource_id = aws_api_gateway_resource.tracks.id
    http_method = aws_api_gateway_method.get_tracks.http_method
    status_code = "200"
    response_models = {
         "application/json" = "Empty"
    }
}

resource "aws_api_gateway_integration" "track_integration" {
  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  resource_id = aws_api_gateway_method.get_tracks.resource_id
  http_method = aws_api_gateway_method.get_tracks.http_method

  integration_http_method = "GET"
  type                    = "HTTP"
  passthrough_behavior    = "WHEN_NO_MATCH"
  uri                     = "https://api.spotify.com/v1/playlists/{playlist-id}/tracks"

      request_parameters = {
        "integration.request.path.playlist-id" = "method.request.path.playlist-id"
        "integration.request.header.Authorization" = "method.request.header.Authorization"
        "integration.request.querystring.limit" = "method.request.querystring.limit"
        "integration.request.querystring.offset" = "method.request.querystring.offset"
    }
  
  credentials = aws_iam_role.lambda_role.arn
}

resource "aws_api_gateway_integration_response" "tracks_int_resp" {
   rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
   resource_id = aws_api_gateway_resource.tracks.id
   http_method = aws_api_gateway_method.get_tracks.http_method
   status_code = aws_api_gateway_method_response.tracks_response.status_code
   response_templates = {
       "application/json" = ""
   }

   depends_on = [aws_api_gateway_integration.track_integration]
}

resource "aws_api_gateway_deployment" "login_deployment" {
  depends_on = [
    aws_api_gateway_integration.info_integration,
    aws_api_gateway_integration.lambda_callback,
    aws_api_gateway_integration.lambda_producer,
    aws_api_gateway_integration.audio_integration,
    aws_api_gateway_integration.playlist_integration1,
    aws_api_gateway_integration.playlist_integration2,
    aws_api_gateway_integration.track_integration,
	aws_api_gateway_integration.post_group_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.Spotiguys.id
  stage_name  = "test"
}

resource "aws_kinesis_stream" "KinesisStream" {
  name = "SpotiguysKinesisDataStream"
  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

resource "aws_amplify_app" "Spotiguys_Amplify" {
  name = "Spotiguys-amplify"
  repository = "https://github.com/swen-514-614-fall2022/spotiguysapp"
  
  build_spec = "${path.module}/amplify.yml"
  
  iam_service_role_arn = aws_iam_role.amplify-role.arn

  environment_variables = {
    _LIVE_UPDATES = "[{\"name\":\"Amplify CLI\",\"pkg\":\"@aws-amplify/cli\",\"type\":\"npm\",\"version\":\"latest\"}]"
	USER_BRANCH = "staging"
  }

  access_token = "" //TODO access tokens
  oauth_token = ""
}

resource "aws_amplify_domain_association" "spotiguys-domain-amplify" {
  app_id = aws_amplify_app.Spotiguys_Amplify.id
  domain_name = "spotiguys.tk"
  
  wait_for_verification = false
  
  # https://example.com
  sub_domain {
    branch_name = aws_amplify_branch.master_branch.branch_name
    prefix      = ""
  }

  # https://www.example.com
  sub_domain {
    branch_name = aws_amplify_branch.master_branch.branch_name
    prefix      = "www"
  }
}

resource "aws_amplify_branch" "master_branch" {
  app_id      = aws_amplify_app.Spotiguys_Amplify.id
  branch_name = "master"

  framework = "React"
  stage     = "PRODUCTION"
}
