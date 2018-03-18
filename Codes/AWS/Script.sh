aws s3 help
aws s3 ls
aws s3 mb s3://maxbrs
aws s3 ls s3://maxbrs

aws s3 cp iliad.mb.txt s3://maxbrs
aws s3 rm s3://maxbrs/iliad.mb.txt

aws s3 sync folder/ s3://maxbrs/folder
aws s3 ls s3://maxbrs/folder
aws s3 cp s3://maxbrs/folder/file .

aws s3 rm --recursive s3://maxbrs/folder



