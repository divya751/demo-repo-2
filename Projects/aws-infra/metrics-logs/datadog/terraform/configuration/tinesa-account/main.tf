terraform {
  backend "s3" {
    bucket = "datadog-terraform-state-husdyrfag-ops"
    region = "eu-west-1"
  }
}

provider "datadog" {
  api_key = "${var.datadog_api_key}"
  app_key = "${var.datadog_app_key}"
}

resource "datadog_user" "aws_tinesa" {
  email = "aws.tinesa@tine.no"
  handle = "aws.tinesa@tine.no"
  is_admin = true
  name = "TINE SA"
}

resource "datadog_user" "rune_engseth" {
  email = "rune.engseth@tine.no"
  handle = "rune.engseth@tine.no"
  name = "Rune Arne Engseth"
}

resource "datadog_user" "arne_solheim" {
  email = "arne.solheim@tine.no"
  handle = "arne.solheim@tine.no"
  name = "Arne Solheim"
}

resource "datadog_user" "krzysztof_grodzicki" {
  email = "krzysztof.grodzicki@tine.no"
  handle = "krzysztof.grodzicki@tine.no"
  name = "Krzysztof Grodzicki"
}

resource "datadog_user" "marius_kristensen" {
  email = "marius.kristensen@tine.no"
  handle = "marius.kristensen@tine.no"
  name = "Marius Kristensen"
}

resource "datadog_user" "christian_johansen" {
  email = "christian.johansen@tine.no"
  handle = "christian.johansen@tine.no"
  name = "Christian Johansen"
}

resource "datadog_user" "andreas_nilsen" {
  email = "andreas.nilsen@tine.no"
  handle = "andreas.nilsen@tine.no"
  name = "Andreas Nilsen"
}

resource "datadog_user" "bjorn_tore_olsen_cintra" {
  email = "bjorn.tore.olsen.cintra@tine.no"
  handle = "bjorn.tore.olsen.cintra@tine.no"
  name = "Bjorn Tore Olsen Cintra"
}

resource "datadog_user" "aman_berhane_ghirmatsion" {
  email = "aman.berhane.ghirmatsion@tine.no"
  handle = "aman.berhane.ghirmatsion@tine.no"
  name = "Aman Berhane Ghirmatsion"
}

resource "datadog_user" "kenneth_leine_chulstad" {
  email = "kenneth.leine.schulstad@tine.no"
  handle = "kenneth.leine.schulstad@tine.no"
  name = "Kenneth Leine Schulstad"
}

resource "datadog_user" "divya_anurag" {
  email = "divya.anurag@tine.no"
  handle = "divya.anurag@tine.no"
  name = "Divya Anurag"
}

resource "datadog_user" "kim_bredesen" {
  email = "kim.bredesen@tine.no"
  handle = "kim.bredesen@tine.no"
  name = "Kim Bredesen"
}

resource "datadog_user" "operation" {
  email = "divya.anurag@tine.no"
  handle = "divya.anurag@tine.no"
  name = "operation"
}

resource "datadog_user" "tom_erik_stower" {
  email = "tom.erik.stower@tine.no"
  handle = "tom.erik.stower@tine.no"
  name = "Tom Erik Støwer"
}

resource "datadog_user" "ramin_esfandiari" {
  email = "ramin.esfandiari@tine.no"
  handle = "ramin.esfandiari@tine.no"
  name = "Ramin Esfandiari"
}

resource "datadog_monitor" "log_errors" {
  name = "Errors detected in logs"
  type = "log alert"
  message = "Notifying @slack-${var.account_alias}"
  query = "logs(\"status:error\").index(\"main\").rollup(\"count\").last(\"1m\") >= 1"
  notify_no_data = false
  include_tags = true
}

//resource "datadog_monitor" "aws_critical" {
//  name = "AWS critical alert!"
//  type = "event alert"
//  message = "Critical event from AWS. \n\nId: {{event.id}}  \nTitle: {{event.title}} \nText: {{event.text}}\nHost name: {{event.host.name}}\n\nNotifying @slack-${var.account_alias}"
//  query = "events('sources:aws priority:all status:error').rollup('count').last('1m') > 0"
//  notify_no_data = false
//  include_tags = true
//}

####################################DASHBOARD METRICS##########################
# Create a new Datadog timeboard
resource "datadog_timeboard" "redis" {
  title = "TINE Timeboard"
  description = "created using the Datadog provider in Terraform"
  read_only = true

  graph {
    title = "ECS Cpuutilization"
    viz = "timeseries"

    request {
      q = "avg:aws.ecs.cpuutilization{*} by {servicename,clustername}"
      type = "line",
      style = {
        palette = "orange",
        type = "solid",
        width = "normal"
      }
    }
  }

  graph {
    title = "ECS Memory Utilization"
    viz = "timeseries"

    request {
      q = "avg:aws.ecs.memory_utilization{$host} by {servicename,clustername}"
      type = "line",
      style = {
        palette = "yellow",
        type = "solid",
        width = "normal"
      }
    }
  }

  graph {
    title = "AWS Kinesis Latency"
    viz = "timeseries"

    request {
      q = "avg:aws.kinesis.get_records_latency{*} by {streamname}"
      type = "line",
      style = {
        palette = "warm",
        type = "solid",
        width = "normal"
      }
    }
  }

  graph {
    title = "Top System CPU by Docker Image"
    viz = "toplist"

    request {
      q = "top(avg:docker.cpu.system{*} by {docker_image}, 10, 'mean', 'desc')"
    }
  }

  graph {
    title = "Top System Memory Cache by Docker Image"
    viz = "toplist"

    request {
      q = "top(avg:docker.mem.cache{*} by {docker_image}, 10, 'mean', 'desc')"
    }
  }

  graph {
    title = "Top System Healthy Hosts Count"
    viz = "toplist"

    request {
      q = "top(avg:aws.applicationelb.healthy_host_count{*} by {host}, 10, 'mean', 'desc')"
    }
  }

  template_variable {
    name = "host"
    prefix = "host"
  }
}
