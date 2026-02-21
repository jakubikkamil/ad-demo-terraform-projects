# Test 00-init: defaults (tags, prefix, location, permissions) are passed through

variables {
  location        = "centralpoland"
  resource_prefix = "test"
  tags = {
    Environment = "test"
    Project     = "blueprint-test"
  }
  admins       = []
  readers      = []
  data_writers = []
  data_readers = []
}

run "defaults_outputs" {
  command = plan

  assert {
    condition     = output.location == "westeurope"
    error_message = "location output should be westeurope"
  }

  assert {
    condition     = output.resource_prefix == "test"
    error_message = "resource_prefix output should be test"
  }

  assert {
    condition     = output.tags["Project"] == "blueprint-test"
    error_message = "tags output should include Project = blueprint-test"
  }

  assert {
    condition     = length(output.admins) == 0 && length(output.readers) == 0
    error_message = "permission lists should be pass-through"
  }
}

run "with_permission_ids" {
  command = plan

  variables {
    admins       = ["00000000-0000-0000-0000-000000000001"]
    readers      = ["00000000-0000-0000-0000-000000000002"]
    data_writers = []
    data_readers = ["00000000-0000-0000-0000-000000000003"]
  }

  assert {
    condition     = length(output.admins) == 1 && output.admins[0] == "00000000-0000-0000-0000-000000000001"
    error_message = "admins should be passed through"
  }

  assert {
    condition     = length(output.data_readers) == 1
    error_message = "data_readers should be passed through"
  }
}
