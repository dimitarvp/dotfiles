-- the html reader inlines <svg> (and fetched images) as data: URIs;
-- base64 blobs are pure noise for the markdown consumers of this recipe
function Image(img)
  if img.src:match('^data:') then
    return {}
  end
end
