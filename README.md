**Warning** this script is still in development. Use at your own risk.

# Pantheon Bulk Site Create/Clone
A script to spin-up multiple Pantheon sites at once. 

It will create a new site for each person from a CSV file. It will also, optionally, clone the code, database and files from an existing site to the newly created sites.

The goal is to allow teachers to spin-up sites for students quickly and easily.

## Requirements
* [Terminus](https://github.com/pantheon-systems/terminus)
* [Terminus site clone plugin](https://github.com/ataylorme/terminus-site-clone)
* [git command line](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

## Usage

### Update or create a .csv file
The rows should be:
`FIRST_NAME,LAST_NAME,PANTHEON_EMAIL`

`FIRST_NAME` and `LAST_NAME` are the names for whom the created site is for. For example, a workshop student.

`PANTHEON_EMAIL` is the email address associated with the Pantheon account for the person above.

See `example-csv-info.csv`.

### Run the script
`sh bulk-site-create-clone.sh <path/to/input-file.csv>` updating `<path/to/input-file.csv>` as necessary.

Fill in the prompts. The scripts asks for:
* Project name
* Source site UUID (optional)
* Source site environment
    - Only if source site is provided
* Organization UUID (optional)
* Upstream machine name (optional)
    - Only if no source site is provided

## License
MIT